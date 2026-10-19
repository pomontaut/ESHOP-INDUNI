require "test_helper"

class VoiceAgentServiceTest < ActiveSupport::TestCase
  Block = Struct.new(:type, :text, :id, :name, :input, keyword_init: true)
  Response = Struct.new(:content)

  # Faux client Anthropic : rejoue des réponses prédéfinies, garde les requêtes.
  class FakeClient
    attr_reader :requests
    def initialize(*responses) = (@responses = responses; @requests = [])
    def messages = self
    def create(**kw) = (@requests << kw; @responses.shift)
  end

  setup do
    @user = users(:two)
    @user.update!(admin: true, allowed_suppliers: [])
    @open = Supplier.create!(name: "Ouvert SA")
    @secret = Supplier.create!(name: "Secret SA", confidential_pricing: true)
    @coude = Product.create!(supplier: @open, reference: "C110", name: "Coude PVC Ø 110 mm 90°", famille: "Canalisations", unit_price: 20.25, unite: "pce")
    Product.create!(supplier: @open, reference: "T110", name: "Tuyau PVC Ø 110 mm", famille: "Canalisations", unit_price: 9.5, unite: "m")
    Product.create!(supplier: @secret, reference: "S1", name: "Coude spécial confidentiel", famille: "Canalisations", unit_price: 99.99, unite: "pce")
  end

  def service(client = nil, **opts)
    VoiceAgentService.new(user: @user, messages: [ { "role" => "user", "content" => "x" } ], client: client, **opts)
  end

  test "search ranks by matched words and never leaks a confidential price" do
    res = service.search("coude pvc 110")
    assert_equal "C110", res.first[:article]
    secret = service.search("coude confidentiel").find { |r| r[:article] == "S1" }
    assert_equal "confidentiel (accords cadre)", secret[:prix]
    assert_not_includes res.to_json, "99.99"
  end

  test "search is restricted to the cart supplier" do
    assert_empty service(nil, cart_supplier: "Secret SA").search("tuyau pvc")
  end

  test "tool loop: search then add_to_cart returns cart actions and the final reply" do
    client = FakeClient.new(
      Response.new([ Block.new(type: :tool_use, id: "t1", name: "search_products", input: { "query" => "coude pvc 110" }) ]),
      Response.new([ Block.new(type: :tool_use, id: "t2", name: "add_to_cart", input: { "catalog" => "Ouvert SA", "article" => "C110", "qty" => 20 }) ]),
      Response.new([ Block.new(type: :text, text: "C'est ajouté.") ])
    )
    out = service(client).call
    assert_equal "C'est ajouté.", out[:reply]
    assert_equal [ { catalog: "Ouvert SA", article: "C110", designation: "Coude PVC Ø 110 mm 90°", qty: 20.0 } ], out[:cart_actions]
    assert_equal 3, client.requests.size
  end

  test "add_to_cart refuses an unknown article, a bad quantity and a second supplier" do
    s = service
    assert s.send(:run_tool, "add_to_cart", { "catalog" => "Ouvert SA", "article" => "NOPE", "qty" => 1 })[:error]
    assert s.send(:run_tool, "add_to_cart", { "catalog" => "Ouvert SA", "article" => "C110", "qty" => 0 })[:error]
    assert s.send(:run_tool, "add_to_cart", { "catalog" => "Ouvert SA", "article" => "C110", "qty" => 2 })[:ok]
    assert s.send(:run_tool, "add_to_cart", { "catalog" => "Secret SA", "article" => "S1", "qty" => 2 })[:error]
  end
end
