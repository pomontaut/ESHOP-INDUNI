require "test_helper"

class Api::NomenclatureControllerTest < ActionDispatch::IntegrationTest
  setup do
    @supplier = Supplier.create!(name: "HGC")
    @pending = Product.create!(
      supplier: @supplier, reference: "PENDING-1", name: "Article à classer",
      unit_price: 9.9, unite: "PCE", manually_added: true, needs_classification: true
    )
    @classified = Product.create!(
      supplier: @supplier, reference: "CLASSIFIED-1", name: "Article déjà classé",
      unit_price: 5.0, unite: "PCE", famille: "Test", manually_added: true, needs_classification: false
    )
  end

  test "index lists only products needing classification" do
    post login_url, params: { email: users(:one).email, password: "password123" }

    get api_nomenclature_url
    assert_response :success
    ids = JSON.parse(response.body).map { |p| p["article"] }
    assert_includes ids, "PENDING-1"
    assert_not_includes ids, "CLASSIFIED-1"
  end

  test "index surfaces the supplier's responsable achat" do
    @supplier.update!(responsable_achat: "Nicolas Guéry")
    post login_url, params: { email: users(:one).email, password: "password123" }

    get api_nomenclature_url
    assert_response :success
    pending = JSON.parse(response.body).find { |p| p["article"] == "PENDING-1" }
    assert_equal "Nicolas Guéry", pending["responsableAchat"]
  end

  test "update sets the category and clears needs_classification" do
    post login_url, params: { email: users(:one).email, password: "password123" }

    patch "/api/nomenclature/#{@pending.id}", params: { famille: "Ciments & Bétons", sousFamille: "Béton" }
    assert_response :success

    @pending.reload
    assert_equal "Ciments & Bétons", @pending.famille
    assert_equal "Béton", @pending.sous_famille
    assert_not @pending.needs_classification?
  end

  test "update rejects a blank famille" do
    post login_url, params: { email: users(:one).email, password: "password123" }

    patch "/api/nomenclature/#{@pending.id}", params: { famille: "" }
    assert_response :unprocessable_entity
    assert @pending.reload.needs_classification?
  end

  test "rejects a user without admin or import-quote permission" do
    post login_url, params: { email: users(:two).email, password: "password123" }

    get api_nomenclature_url
    assert_response :forbidden
  end

  test "allows a user granted the import-quote permission" do
    users(:two).update!(can_import_quote: true)
    post login_url, params: { email: users(:two).email, password: "password123" }

    get api_nomenclature_url
    assert_response :success
  end
end
