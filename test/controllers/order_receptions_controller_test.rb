require "test_helper"

class OrderReceptionsControllerTest < ActionDispatch::IntegrationTest
  def create_order_via_api
    post login_url, params: { email: users(:one).email, password: "password123" }
    post api_orders_url, params: {
      chantier: "12345-Chantier Test", delai: "Urgent", supplier: "HGC Test Fixture",
      items: [ { article: "ART-1", designation: "Article test", qty: 1, prix: 10.0 } ]
    }
    Order.order(:id).last
  end

  test "show renders the confirmation page for a valid token" do
    order = create_order_via_api
    delete logout_url

    get order_reception_url(order.reception_token)
    assert_response :success
    assert_match(/J.ai bien reçu cette commande/, response.body)
  end

  test "show renders 404 for an invalid token" do
    get order_reception_url("does-not-exist")
    assert_response :not_found
  end

  test "confirm marks the order as received and notifies the author" do
    order = create_order_via_api
    author = order.user
    delete logout_url

    assert_nil order.reload.reception_confirmed_at

    post confirm_order_reception_url(order.reception_token)
    assert_response :success

    order.reload
    assert order.reception_confirmed_at.present?

    notif = ActionMailer::Base.deliveries.find { |m| m.subject.include?(order.number) && m.subject.include?("confirmé") }
    assert notif, "the order's author must be notified when the supplier confirms reception"
    assert_includes notif.to, author.email
  end

  test "confirming twice does not reset the timestamp or resend the notification" do
    order = create_order_via_api
    delete logout_url

    post confirm_order_reception_url(order.reception_token)
    first_timestamp = order.reload.reception_confirmed_at
    notif_count_after_first = ActionMailer::Base.deliveries.count { |m| m.subject.include?(order.number) && m.subject.include?("confirmé") }

    post confirm_order_reception_url(order.reception_token)
    order.reload
    assert_equal first_timestamp, order.reception_confirmed_at
    notif_count_after_second = ActionMailer::Base.deliveries.count { |m| m.subject.include?(order.number) && m.subject.include?("confirmé") }
    assert_equal notif_count_after_first, notif_count_after_second, "clicking the link again must not send a second notification"
  end
end
