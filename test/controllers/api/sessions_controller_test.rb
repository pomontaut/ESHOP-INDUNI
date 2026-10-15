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

  test "me exposes a chantier's dedicated delivery contact, distinct from its contremaître" do
    Chantier.create!(
      nom: "12601-Halle des Rouettes", contremaitre: "GAILLARD Cédric", natel_contremaitre: "+41790000000",
      contact_livraison: "PINTO Pedro", natel_livraison: "+41763656892", email_livraison: "ppinto@induni.ch"
    )
    post login_url, params: { email: users(:one).email, password: "password123" }

    get api_me_url
    body = JSON.parse(response.body)

    chantier = body["chantiers"].find { |c| c["nom"] == "12601-Halle des Rouettes" }
    assert_equal "GAILLARD Cédric", chantier["contact"]
    assert_equal "PINTO Pedro", chantier["contactLivraison"]
    assert_equal "+41763656892", chantier["telephoneLivraison"]
  end

  test "admin test environment shows only the site-lead banner, and can be left" do
    post login_url, params: { email: users(:one).email, password: "password123" }

    post api_test_profile_url, params: { profile: "Contremaître" }
    assert_response :success
    body = JSON.parse(get(api_me_url) && response.body)
    assert_equal false, body["admin"]
    assert_equal true, body["real_admin"]
    assert_equal "Contremaître", body["test_profile"]
    assert_equal true, body["can_view_dashboard"]
    assert_equal false, body["can_create_users"]

    post api_test_profile_url, params: { profile: "Conducteur de travaux" }
    get api_me_url
    assert_equal false, JSON.parse(response.body)["can_view_dashboard"]

    delete api_test_profile_url
    get api_me_url
    assert_equal true, JSON.parse(response.body)["admin"]
  end

  test "non-admin cannot start the test environment" do
    post login_url, params: { email: users(:two).email, password: "password123" }
    post api_test_profile_url, params: { profile: "Contremaître" }
    assert_response :forbidden
  end

  test "admin development environment keeps full admin rights and flags dev_mode" do
    post login_url, params: { email: users(:one).email, password: "password123" }
    post api_test_profile_url, params: { profile: "Développement" }
    assert_response :success
    get api_me_url
    body = JSON.parse(response.body)
    assert_equal true, body["admin"]
    assert_equal true, body["dev_mode"]
    assert_equal "Développement", body["test_profile"]

    delete api_test_profile_url
    get api_me_url
    body = JSON.parse(response.body)
    assert_equal false, body["dev_mode"]
    assert_nil body["test_profile"]
  end
end
