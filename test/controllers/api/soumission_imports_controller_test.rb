require "test_helper"

class Api::SoumissionImportsControllerTest < ActionDispatch::IntegrationTest
  FakeExtractor = Struct.new(:bytes) do
    def truncated = false
    def extract
      [ { pos: "211.101", designation: "Tuyau drainage PVC DN 100 perforé", quantity: 120, unit: "ml", cfc: "211", chapter: "Drainage", highlight: "jaune" },
        { pos: "211.102", designation: "Pièce introuvable xyzzy", quantity: 3, unit: "pce", cfc: "211", chapter: "Drainage", highlight: "autre" } ]
    end
  end

  setup do
    post login_url, params: { email: users(:one).email, password: "password123" }
    @supplier = Supplier.create!(name: "Fourn Soum", email: "a@x.ch")
    @drain = Product.create!(supplier: @supplier, reference: "DR-100", name: "Tuyau drainage PVC DN 100 perforé", unit_price: 12.5, unite: "ml", famille: "Drainage")
    @other = Product.create!(supplier: @supplier, reference: "DR-200", name: "Tuyau drainage PVC DN 200 perforé", unit_price: 30, unite: "ml", famille: "Drainage")
    @sika = Supplier.create!(name: "Sika Soum", email: "s@x.ch", confidential_pricing: true)
    Product.create!(supplier: @sika, reference: "SK-1", name: "Tuyau drainage PVC DN 100 perforé Sika", unit_price: 5, unite: "ml", famille: "Drainage")
  end

  test "réservé à l'environnement Développement" do
    post "/api/soumission_imports/price", params: { lines: [ { designation: "x" } ] }
    assert_response :forbidden
  end

  test "chiffre les positions, jamais de prix confidentiel, ligne introuvable = à demander" do
    post api_test_profile_url, params: { profile: "Développement" }
    Api::SoumissionImportsController.class_eval { def extractor = Api::SoumissionImportsControllerTest::FakeExtractor }
    post "/api/soumission_imports", params: { file: Rack::Test::UploadedFile.new(StringIO.new("%PDF"), "application/pdf", original_filename: "s.pdf") }
    assert_response :success
    items = JSON.parse(response.body)["items"]
    first = items.first
    assert_equal "chiffre", first["status"]
    assert_equal "DR-100", first["candidates"].first["reference"]
    assert_equal 1500.0, first["candidates"].first["total"]
    sika = first["candidates"].find { |c| c["supplier"] == "Sika Soum" }
    assert_nil sika["prix"] if sika
    assert_nil sika["total"] if sika
    assert_equal "a_demander", items.last["status"]
    assert_empty items.last["candidates"]
  ensure
    Api::SoumissionImportsController.class_eval { def extractor = SoumissionExtractorService }
  end

  test "mémoire : un rapprochement validé passe en tête, un refusé disparaît" do
    post api_test_profile_url, params: { profile: "Développement" }
    post "/api/soumission_imports/learn", params: { designation: "Tuyau drainage PVC DN 100 perforé", supplier: "Fourn Soum", reference: "DR-200", status: "confirmed" }
    assert_response :success
    post "/api/soumission_imports/learn", params: { designation: "Tuyau drainage PVC DN 100 perforé", supplier: "Fourn Soum", reference: "DR-100", status: "rejected" }
    post "/api/soumission_imports/price", params: { lines: [ { designation: "Tuyau drainage PVC DN 100 perforé", quantity: 10, unit: "ml" } ] }
    cands = JSON.parse(response.body)["items"].first["candidates"]
    assert_equal "DR-200", cands.first["reference"]
    assert cands.first["learned"]
    assert_not_includes cands.map { |c| c["reference"] }, "DR-100"
  end
end
