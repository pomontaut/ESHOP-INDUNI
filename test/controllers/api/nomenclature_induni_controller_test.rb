require "test_helper"

class Api::NomenclatureInduniControllerTest < ActionDispatch::IntegrationTest
  setup do
    @supplier = Supplier.create!(name: "HG COMMERCIALE")
    Product.create!(supplier: @supplier, reference: "100096949", name: "Carrelet", unit_price: 1, unite: "m3")
    NomenclatureEntry.create!(induni_reference: "340200001", supplier_name: "HG COMMERCIALE", supplier_reference: "100096949",
                              induni_designation: "Carrelets 80/120 400cm", price_unit: "m3",
                              search_keywords: "carrelet ; lambourde")
    NomenclatureEntry.create!(induni_reference: "340200001", supplier_name: "Leuba HIAG", supplier_reference: "127466")
  end

  test "admin lists the library with catalog presence and no price" do
    post login_url, params: { email: users(:one).email, password: "password123" }

    get api_nomenclature_induni_url
    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal 2, rows.size
    assert_equal true,  rows.find { |r| r["supplierReference"] == "100096949" }["inCatalog"]
    assert_equal false, rows.find { |r| r["supplierReference"] == "127466" }["inCatalog"]
    assert_equal "carrelet ; lambourde", rows.find { |r| r["supplierReference"] == "100096949" }["searchKeywords"]
    assert rows.none? { |r| r.key?("prix") }
  end

  test "non-admin gets 403" do
    post login_url, params: { email: users(:two).email, password: "password123" }

    get api_nomenclature_induni_url
    assert_response :forbidden
  end

  test "seed drops lines that are no longer in the JSON (renumbered library)" do
    NomenclatureEntry.create!(induni_reference: "999999999", supplier_name: "HG COMMERCIALE", supplier_reference: "OLD")
    NomenclatureEntry.seed_from_json!
    assert_nil NomenclatureEntry.find_by(supplier_reference: "OLD")
    assert NomenclatureEntry.where.not(search_keywords: [ nil, "" ]).exists?
  end

  test "seed is idempotent" do
    NomenclatureEntry.delete_all
    first = NomenclatureEntry.seed_from_json!
    assert_equal first, NomenclatureEntry.seed_from_json!
    assert_operator first, :>=, 200
  end
end
