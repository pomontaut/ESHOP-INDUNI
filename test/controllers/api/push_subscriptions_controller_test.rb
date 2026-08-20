require "test_helper"

class Api::PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { email: users(:one).email, password: "password123" }
  end

  test "create stores a new subscription for the current user" do
    assert_difference -> { users(:one).push_subscriptions.count }, 1 do
      post api_push_subscriptions_url, params: {
        endpoint: "https://push.example.com/abc",
        keys: { p256dh: "fake-p256dh", auth: "fake-auth" }
      }
    end
    assert_response :no_content
  end

  test "create is idempotent for the same endpoint" do
    post api_push_subscriptions_url, params: { endpoint: "https://push.example.com/abc", keys: { p256dh: "a", auth: "b" } }
    assert_difference -> { users(:one).push_subscriptions.count }, 0 do
      post api_push_subscriptions_url, params: { endpoint: "https://push.example.com/abc", keys: { p256dh: "a2", auth: "b2" } }
    end
    assert_equal "a2", users(:one).push_subscriptions.find_by(endpoint: "https://push.example.com/abc").p256dh_key
  end

  test "destroy removes the subscription for the given endpoint" do
    users(:one).push_subscriptions.create!(endpoint: "https://push.example.com/abc", p256dh_key: "a", auth_key: "b")
    assert_difference -> { users(:one).push_subscriptions.count }, -1 do
      delete api_push_subscriptions_url, params: { endpoint: "https://push.example.com/abc" }
    end
    assert_response :no_content
  end

  test "requires authentication" do
    delete logout_url
    post api_push_subscriptions_url, params: { endpoint: "https://push.example.com/abc", keys: { p256dh: "a", auth: "b" } }
    assert_response :unauthorized
  end
end
