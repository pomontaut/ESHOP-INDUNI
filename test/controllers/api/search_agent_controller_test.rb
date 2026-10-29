require "test_helper"

class Api::SearchAgentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sup = Supplier.create!(name: "Canplast")
    @prod = Product.create!(supplier: @sup, reference: "LDEY250200", name: "Embranchement PVC SN4 250/200", unit_price: 1, unite: "u", famille: "Canalisations PVC")
    NomenclatureEntry.create!(induni_reference: "381100018", induni_designation: "Embranchement PVC SN4 250/200mm 45°", supplier_name: "Canplast",
                              supplier_reference: "LDEY250200", search_keywords: "culotte")
  end

  def login(user) = post(login_url, params: { email: user.email, password: "password123" })
  def say(text) = post("/api/search_agent/chat", params: { message: text }, as: :json)

  test "chat is admin only" do
    login(users(:two))
    say "aide"
    assert_response :forbidden
    get "/api/search_agent"
    assert_response :forbidden
  end

  test "keywords added by INDUNI number reach every user through /api/products" do
    login(users(:one))
    say "ajoute les mots clefs raccord en Y, piquage pour 381100018"
    assert_response :success
    body = JSON.parse(response.body)
    assert body["changed"]
    assert_equal "culotte ; raccord en Y, piquage", body["updates"].first["induniKeywords"]

    login(users(:two))
    get api_products_url
    row = JSON.parse(response.body).find { |p| p["article"] == "LDEY250200" }
    assert_equal "culotte ; raccord en Y, piquage", row["induniKeywords"]
  end

  test "keywords can target an article by its name and ambiguity is reported" do
    Product.create!(supplier: @sup, reference: "LDEY315200", name: "Embranchement PVC SN4 315/200", unit_price: 1, unite: "u")
    login(users(:one))
    say "ajoute le mot clef branchement pour Embranchement PVC SN4"
    assert_not JSON.parse(response.body)["changed"]
    assert_match(/Plusieurs articles|381100018/, JSON.parse(response.body)["reply"])
    say "ajoute le mot clef branchement pour Embranchement PVC SN4 250/200mm"
    assert JSON.parse(response.body)["changed"]
  end

  test "synonyms are memorised, served to everyone and forgotten" do
    login(users(:one))
    say "synonyme : siphon de cour = avaloir, grille de sol"
    body = JSON.parse(response.body)
    assert body["changed"]
    assert_equal [ "avaloir", "grille de sol" ], body["synonyms"].first["values"]

    login(users(:two))
    get "/api/search_memory"
    assert_equal "siphon de cour", JSON.parse(response.body)["synonyms"].first["term"]

    login(users(:one))
    say "quand on tape cloche, il faut trouver bouchon"
    assert_equal true, SearchMemory.find_by(term: "cloche").one_way
    say "oublie siphon de cour"
    assert_nil SearchMemory.find_by(term: "siphon de cour")
  end

  test "suggestions come from real journeys and can be validated" do
    login(users(:two))
    t = Time.current
    ms = ->(x) { (x.to_f * 1000).to_i }
    post "/api/usage/events", params: { session: "s1", events: [
      { k: "search", t: ms.(t - 60), d: { q: "branchement y 250", results: 0 } },
      { k: "search", t: ms.(t - 40), d: { q: "embranchement 250/200", results: 3 } },
      { k: "add_to_cart", t: ms.(t - 20), d: { article: "LDEY250200", catalog: "Canplast", designation: "Embranchement PVC SN4 250/200", via: "recherche" } }
    ] }, as: :json

    login(users(:one))
    say "suggestions"
    reply = JSON.parse(response.body)["reply"]
    assert_match(/branchement y 250/, reply)
    id = SearchMemory.where(status: "suggested").find_by(value: "branchement y 250").id
    say "valide #{id}"
    assert_equal "active", SearchMemory.find(id).status
    assert_includes SearchMemory.keywords_by_product[[ "Canplast", "LDEY250200" ]], "branchement y 250"

    say "bilan"
    assert_match(/recherche\(s\)/, JSON.parse(response.body)["reply"])
  end

  # --- cerveau conversationnel (API Claude simulée) ---
  Block = Struct.new(:type, :text, :id, :name, :input, keyword_init: true)
  Resp  = Struct.new(:content)

  class FakeClient
    attr_reader :calls
    def initialize(*steps) = (@steps = steps; @calls = [])
    def messages = self
    def create(**kw)
      @calls << kw
      @steps.shift.call(kw)
    end
  end

  test "free-text remark is understood: the brain applies a ranking rule through tools and explains" do
    login(users(:one))
    agent = SearchAgent.new(users(:one))
    fake = FakeClient.new(
      ->(_) { Resp.new([ Block.new(type: :tool_use, id: "t1", name: "add_ranking_rule",
                                   input: { label: "Drainage après plein", product_has_any: [ "drainage", "perforé" ], query_lacks_any: [ "drain" ], points: -150 }) ]) },
      ->(kw) { assert_match(/Règle #\d+ mémorisée/, kw[:messages].last[:content].first[:content])
               Resp.new([ Block.new(type: :text, text: "J'ai descendu les tubes de drainage ; testez avec « teste tuyau pvc 125 sn4 compact 5m ».") ]) }
    )
    res = SearchAgent::Brain.new(agent, users(:one), client: fake).run("quand je tape tuyau pvc 125 sn4 compact 5m je tombe sur le tube de drainage, pourquoi ?",
                                                                      [ { q: "tuyau pvc 125 sn4 compact 5m", total: 10, top: [] } ])
    assert res.changed
    assert res.synonyms
    assert_match(/descendu les tubes de drainage/, res.reply)
    rule = SearchMemory.rules_json.find { |r| r[:label] == "Drainage après plein" }
    assert_equal(-150, rule[:points])
    assert_equal [ "drainage", "perfore" ], rule[:product_has_any]
    assert_match(/Contexte moteur/, fake.calls.first[:messages].first[:content])
  end

  test "without API key the rule-based fallback explains using the engine context and accepts a rule command" do
    login(users(:one))
    ENV.delete("ANTHROPIC_API_KEY")
    engine = [ { q: "tuyau pvc 125 sn4 compact 5m", total: 40,
                 top: [ { designation: "Tuyau de drainage PVC COMPACT SN4", catalog: "Canplast", article: "LDTP125", induni: "380700004", score: 1618, why: "tous les mots retrouvés ; contient « drainage » absent de la requête" } ],
                 targets: [ { designation: "Tuyau PVC COMPACT SN4 125", catalog: "HG COMMERCIALE", article: "100063069", rank: 2, score: 1613, why: "tous les mots retrouvés" } ] } ]
    post "/api/search_agent/chat", params: { message: "pourquoi je tombe sur le drainage et non sur 380300065 ?", engine: engine }, as: :json
    reply = JSON.parse(response.body)["reply"]
    assert_match(/LDTP125/, reply)
    assert_match(/rang 2/, reply)

    say "règle : pénalise drainage, perforé sauf si on tape drain, drainage (-150)"
    assert JSON.parse(response.body)["changed"]
    assert(SearchMemory.rules_json.any? { |r| !r[:builtin] && r[:points] == -150 && r[:product_has_any].include?("drainage") })
  end

  test "built-in rules are served to every user and can be disabled by the agent" do
    login(users(:two))
    get "/api/search_memory"
    ids = JSON.parse(response.body)["rules"].map { |r| r["id"] }
    assert_includes ids, "b-drainage"

    login(users(:one))
    SearchAgent.new(users(:one)).disable_rule("b-drainage")
    login(users(:two))
    get "/api/search_memory"
    assert_not_includes JSON.parse(response.body)["rules"].map { |r| r["id"] }, "b-drainage"
  end

  test "unknown phrase without API key explains why it was not understood" do
    login(users(:one))
    ENV.delete("ANTHROPIC_API_KEY")
    say "je trouve que la recherche devrait être plus intelligente"
    assert_match(/ANTHROPIC_API_KEY/, JSON.parse(response.body)["reply"])
  end

  test "API failure falls back to simple commands and says so" do
    login(users(:one))
    ENV["ANTHROPIC_API_KEY"] = "test-key"
    SearchAgent::Brain.define_singleton_method(:new) { |*| Object.new.tap { |o| o.define_singleton_method(:run) { |*| raise "boom" } } }
    say "synonyme : culotte = embranchement"
    body = JSON.parse(response.body)
    assert_match(/indisponible/, body["reply"])
    assert body["changed"]
  ensure
    ENV.delete("ANTHROPIC_API_KEY")
    SearchAgent::Brain.singleton_class.send(:remove_method, :new)
  end
end
