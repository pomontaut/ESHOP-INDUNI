require "test_helper"

class Api::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "me exposes the new feature permissions for a basic user" do
    post login_url, params: { email: users(:two).email, password: "password123" }

    get api_me_url
    body = JSON.parse(response.body)

    assert_equal false, body["can_view_dashboard"]
    assert_equal false, body["can_view_analysis"]
    assert_equal false, body["can_view_nomenclature"]
  end

  test "me exposes the new feature permissions as true for an admin" do
    post login_url, params: { email: users(:one).email, password: "password123" }

    get api_me_url
    body = JSON.parse(response.body)

    assert_equal true, body["can_view_dashboard"]
    assert_equal true, body["can_view_analysis"]
    assert_equal true, body["can_view_nomenclature"]
  end

  test "me reflects an explicitly granted feature permission for a non-admin" do
    users(:two).update!(can_view_dashboard: true)
    post login_url, params: { email: users(:two).email, password: "password123" }

    get api_me_url
    body = JSON.parse(response.body)

    assert_equal true, body["can_view_dashboard"]
    assert_equal false, body["can_view_analysis"]
  end

  test "me exposes each supplier's real configured default e-mail" do
    Supplier.create!(name: "HGC", email: "commandes-reelles@hgc.ch")
    Supplier.create!(name: "Sans e-mail")
    post login_url, params: { email: users(:one).email, password: "password123" }

    get api_me_url
    body = JSON.parse(response.body)

    assert_equal "commandes-reelles@hgc.ch", body["supplierDefaultEmails"]["HGC"]
    assert_not body["supplierDefaultEmails"].key?("Sans e-mail")
  end

  test "me exposes each visible chantier's canton" do
    Chantier.create!(nom: "12601-Halle des Rouettes", canton: "GENEVE")
    post login_url, params: { email: users(:one).email, password: "password123" }

    get api_me_url
    body = JSON.parse(response.body)

    chantier = body["chantiers"].find { |c| c["nom"] == "12601-Halle des Rouettes" }
    assert_equal "GENEVE", chantier["canton"]
  end
end
