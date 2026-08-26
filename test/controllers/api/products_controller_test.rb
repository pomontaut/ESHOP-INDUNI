require "test_helper"

class Api::ProductsControllerTest < ActionDispatch::IntegrationTest
  test "index requires authentication — the full catalog must never be public" do
    get api_products_url
    assert_response :unauthorized
  end

  test "index only returns products from suppliers visible to the current user" do
    visible_supplier = Supplier.create!(name: "Fournisseur ouvert")
    restricted_supplier = Supplier.create!(name: "Fournisseur restreint", visible_sectors: [ "BAT GE" ])
    Product.create!(supplier: visible_supplier, reference: "ART-OUVERT", name: "Article ouvert", famille: "Voirie")
    Product.create!(supplier: restricted_supplier, reference: "ART-RESTREINT", name: "Article restreint", famille: "Voirie")

    user = users(:two)
    user.update!(sector: "GC", admin: false, allowed_suppliers: [])
    post login_url, params: { email: user.email, password: "password123" }

    get api_products_url
    assert_response :success
    catalogs = JSON.parse(response.body).map { |p| p["catalog"] }
    assert_includes catalogs, "Fournisseur ouvert"
    assert_not_includes catalogs, "Fournisseur restreint"
  end

  test "index masks the price of products from a supplier under confidential pricing" do
    confidential_supplier = Supplier.create!(name: "Fournisseur confidentiel", confidential_pricing: true)
    Product.create!(supplier: confidential_supplier, reference: "ART-CONF", name: "Article confidentiel", famille: "Adjuvants", unit_price: 1200.0)

    user = users(:two)
    user.update!(admin: false, allowed_suppliers: [])
    post login_url, params: { email: user.email, password: "password123" }

    get api_products_url
    assert_response :success
    product = JSON.parse(response.body).find { |p| p["article"] == "ART-CONF" }
    assert_equal true, product["confidential"]
    assert_equal 0.0, product["prix"]
  end

  test "index responds with Cache-Control: no-store so no browser ever serves a stale catalog" do
    # Confirmed on production: the same account, same data, could show an
    # empty or outdated catalog on one browser but not another — some
    # engines apply their own heuristic caching to a JSON GET response that
    # carries no explicit cache header, and never re-fetch it even after a
    # full page reload.
    post login_url, params: { email: users(:one).email, password: "password123" }
    get api_products_url
    assert_equal "no-store", response.headers["Cache-Control"]
  end
end
