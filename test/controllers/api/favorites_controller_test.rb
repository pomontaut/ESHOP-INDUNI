require "test_helper"

class Api::FavoritesControllerTest < ActionDispatch::IntegrationTest
  test "index requires authentication" do
    get api_favorites_url
    assert_response :unauthorized
  end

  test "toggle adds then removes a favorite, scoped to the user" do
    post login_url, params: { email: users(:one).email, password: "password123" }
    item = { catalog: "HG COMMERCIALE", article: "12345", designation: "Coude 45" }

    post toggle_api_favorites_url, params: item
    assert_response :success
    assert_equal true, JSON.parse(response.body)["favorite"]

    get api_favorites_url
    assert_equal [ item.stringify_keys ], JSON.parse(response.body)
    assert_equal 0, users(:two).favorites.count

    post toggle_api_favorites_url, params: item
    assert_equal false, JSON.parse(response.body)["favorite"]
    assert_equal 0, users(:one).favorites.count
  end

  test "toggle requires catalog and article" do
    post login_url, params: { email: users(:one).email, password: "password123" }
    post toggle_api_favorites_url, params: { catalog: "", article: "" }
    assert_response :unprocessable_entity
  end
end
