require "test_helper"

class WebPushNotifierTest < ActiveSupport::TestCase
  test "does nothing when the user has no push subscription" do
    user = users(:one)
    assert_equal 0, user.push_subscriptions.count
    assert_nothing_raised do
      WebPushNotifier.notify(user, title: "Test", body: "Test body")
    end
  end

  test "does nothing when user is nil" do
    assert_nothing_raised do
      WebPushNotifier.notify(nil, title: "Test", body: "Test body")
    end
  end

  test "deletes the subscription when the push service reports it expired" do
    user = users(:one)
    sub = user.push_subscriptions.create!(
      endpoint: "https://push.example.com/expired",
      p256dh_key: Base64.urlsafe_encode64(OpenSSL::PKey::EC.generate("prime256v1").public_key.to_bn.to_s(2), padding: false),
      auth_key: Base64.urlsafe_encode64(Random.new.bytes(16), padding: false)
    )
    fake_response = Struct.new(:body).new("Gone")
    original_payload_send = Webpush.method(:payload_send)
    Webpush.define_singleton_method(:payload_send) do |*args, **kwargs|
      raise Webpush::ExpiredSubscription.new(fake_response, "push.example.com")
    end
    begin
      WebPushNotifier.notify(user, title: "Test", body: "Test body")
    ensure
      Webpush.define_singleton_method(:payload_send, original_payload_send)
    end
    assert_not PushSubscription.exists?(sub.id)
  end
end
