require "test_helper"

class Api::PreviewsControllerTest < ActionDispatch::IntegrationTest
  def login(user)
    post login_url, params: { email: user.email, password: "password123" }
  end

  test "admin can switch to the contremaitre test profile and sees only its banner" do
    login(users(:one))
    post api_preview_url, params: { profile: "CONTREMAITRE" }, as: :json
    assert_response :success

    body = JSON.parse(get(api_me_url) && response.body)
    assert_equal false, body["admin"]
    assert_equal "CONTREMAITRE", body["preview_profile"]
    assert_equal true, body["can_view_dashboard"]
    assert_equal true, body["can_create_orders"]
    assert_equal false, body["can_create_users"]
    assert_equal false, body["can_view_analysis"]
    assert_equal false, body["can_view_nomenclature"]
  end

  test "leaving the test mode restores the admin view" do
    login(users(:one))
    post api_preview_url, params: { profile: "CONDUCTEUR DE TRAVAUX" }, as: :json
    delete api_preview_url

    get api_me_url
    body = JSON.parse(response.body)
    assert_equal true, body["admin"]
    assert_nil body["preview_profile"]
    assert_equal true, body["can_view_analysis"]
  end

  test "unknown profile is rejected" do
    login(users(:one))
    post api_preview_url, params: { profile: "DIRECTEUR" }, as: :json
    assert_response :unprocessable_entity
  end

  test "non admin cannot enable the test mode and a stale session key has no effect" do
    login(users(:two))
    post api_preview_url, params: { profile: "CONTREMAITRE" }, as: :json
    assert_response :forbidden

    get api_me_url
    assert_nil JSON.parse(response.body)["preview_profile"]
  end

  test "in test mode the orders list is limited to the admin's own orders" do
    login(users(:one))
    post api_preview_url, params: { profile: "CONTREMAITRE" }, as: :json
    get api_orders_url
    assert_response :success
    assert JSON.parse(response.body).all? { |o| o["user_name"] == users(:one).full_name }
  end

  test "admin users page offers the test mode buttons and the layout shows the active profile" do
    login(users(:one))
    get admin_users_url
    assert_response :success
    assert_select "[data-preview-profile=?]", "CONTREMAITRE"
    assert_select "[data-preview-profile=?]", "CONDUCTEUR DE TRAVAUX"

    post api_preview_url, params: { profile: "CONTREMAITRE" }, as: :json
    get admin_users_url
    assert_select ".alert-warning", /Mode test.*Contremaître/m
  end
end
