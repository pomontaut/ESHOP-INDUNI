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
end
