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

  test "index only exposes Swisspor's Isolation famille, masking the rest of its catalog" do
    swisspor = Supplier.create!(name: "Swisspor")
    Product.create!(supplier: swisspor, reference: "SWI-ISO", name: "Panneau isolant", famille: "Isolation")
    Product.create!(supplier: swisspor, reference: "SWI-ETA", name: "Membrane étanchéité", famille: "Étanchéité")
    Product.create!(supplier: swisspor, reference: "SWI-TOI", name: "Substrat toiture végétalisée", famille: "Toitures végétalisées")

    post login_url, params: { email: users(:one).email, password: "password123" }
    get api_products_url
    assert_response :success

    articles = JSON.parse(response.body).select { |p| p["catalog"] == "Swisspor" }.map { |p| p["article"] }
    assert_includes articles, "SWI-ISO"
    assert_not_includes articles, "SWI-ETA"
    assert_not_includes articles, "SWI-TOI"
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

  test "test-only e-shops (Tinguely, SGTT) are hidden except in the admin development environment" do
    tinguely = Supplier.create!(name: "Tinguely", visible_cantons: [ "VAUD" ])
    Product.create!(supplier: tinguely, reference: "TING-01", name: "Forfait aspiratrice", famille: "Aspiratrice & pompage", unit_price: 1150)

    post login_url, params: { email: users(:one).email, password: "password123" }
    get api_products_url
    assert_not_includes JSON.parse(response.body).map { |p| p["catalog"] }, "Tinguely"
    get api_me_url
    assert_not_includes JSON.parse(response.body)["allowed_suppliers"], "Tinguely"

    post api_test_profile_url, params: { profile: "Développement" }
    get api_products_url
    assert_includes JSON.parse(response.body).map { |p| p["catalog"] }, "Tinguely"
    get api_me_url
    body = JSON.parse(response.body)
    assert_includes body["allowed_suppliers"], "Tinguely"
    assert_equal [ "VAUD" ], body["supplierVisibleCantons"]["Tinguely"]
  end

  test "test-only e-shops are never exposed to a non-admin user" do
    sgtt = Supplier.create!(name: "SGTT", visible_cantons: [ "GENEVE" ])
    Product.create!(supplier: sgtt, reference: "SGTT-01", name: "Pompage", famille: "Aspiratrice & pompage", unit_price: 280)
    user = users(:two)
    user.update!(admin: false, allowed_suppliers: [])
    post login_url, params: { email: user.email, password: "password123" }
    get api_products_url
    assert_not_includes JSON.parse(response.body).map { |p| p["catalog"] }, "SGTT"
  end
end
