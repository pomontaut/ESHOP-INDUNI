require "test_helper"

class GenericOrdersControllerTest < ActionDispatch::IntegrationTest
  test "redirects to login when not authenticated" do
    get bon_de_commande_url
    assert_redirected_to login_path
  end

  test "redirects a user without the generic-order permission" do
    post login_url, params: { email: users(:two).email, password: "password123" }
    get bon_de_commande_url
    assert_redirected_to root_path
  end

  test "renders the form for a user granted the generic-order permission" do
    users(:two).update!(can_generic_order: true)
    post login_url, params: { email: users(:two).email, password: "password123" }
    get bon_de_commande_url
    assert_response :success
    assert_match "Générateur de bons de commande", response.body
  end

  test "renders the form for an admin regardless of the flag" do
    post login_url, params: { email: users(:one).email, password: "password123" }
    get bon_de_commande_url
    assert_response :success
  end
end
