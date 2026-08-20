require "test_helper"

class Api::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { email: users(:one).email, password: "password123" }
  end

  test "preview_pdf converts an HTML bon de commande into a real PDF" do
    html = "<html><body><h1>Bon de commande BC-123456</h1></body></html>"
    post preview_pdf_api_orders_url, params: { html: html, filename: "BC-123456_bon_de_commande" }

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF"), "response body must be a real PDF"
  end

  test "preview_pdf rejects an empty html body" do
    post preview_pdf_api_orders_url, params: { html: "" }
    assert_response :unprocessable_entity
  end

  test "preview_pdf requires authentication" do
    delete logout_url
    post preview_pdf_api_orders_url, params: { html: "<html></html>" }
    assert_response :unauthorized
  end

  test "next_number previews the number the next order will get" do
    get next_number_api_orders_url
    assert_response :success
    predicted = JSON.parse(response.body)["number"]
    assert_match(/\AESHOP_\d+\z/, predicted)

    post api_orders_url, params: {
      chantier: "12345-Chantier Test", delai: "Urgent", supplier: "HGC Test Fixture",
      items: [ { article: "ART-1", designation: "Article test", qty: 1, prix: 10.0 } ]
    }
    assert_equal predicted, JSON.parse(response.body)["order_number"]
  end

  test "create uses a custom subject and body when provided" do
    post api_orders_url, params: {
      chantier: "12345-Chantier Test", delai: "Urgent", supplier: "HGC Test Fixture",
      subject: "Titre personnalisé", body: "Corps personnalisé du message.",
      items: [ { article: "ART-1", designation: "Article test", qty: 1, prix: 10.0 } ]
    }
    assert_response :success

    mail = ActionMailer::Base.deliveries.last
    assert_equal "Titre personnalisé", mail.subject
    body = mail.text_part ? mail.text_part.body.to_s : mail.body.to_s
    assert_match(/Corps personnalisé du message\./, body)
    assert_no_match(/RÉSUMÉ DE LA COMMANDE/, body)
  end

  test "create sends the order to an overridden recipient and cc when provided" do
    post api_orders_url, params: {
      chantier: "12345-Chantier Test", delai: "Urgent", supplier: "HGC Test Fixture",
      to: "verifie@induni.ch", cc: "technicien@induni.ch, invalide-sans-arobase",
      items: [ { article: "ART-1", designation: "Article test", qty: 1, prix: 10.0 } ]
    }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "verifie@induni.ch", body["supplier_email"]

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "verifie@induni.ch" ], mail.to
    assert_includes mail.cc, "technicien@induni.ch", "the malformed cc entry must be dropped, not raise"
  end

  test "create always cc's the order's author, even with no cc provided, and requests a read receipt" do
    author = users(:one)

    post api_orders_url, params: {
      chantier: "12345-Chantier Test", delai: "Urgent", supplier: "HGC Test Fixture",
      items: [ { article: "ART-1", designation: "Article test", qty: 1, prix: 10.0 } ]
    }
    assert_response :success

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ author.email ], mail.cc, "the author must always be cc'd, even with an empty cc field"
    assert_equal author.email, mail["Disposition-Notification-To"].to_s
    assert_equal author.email, mail["Return-Receipt-To"].to_s
  end

  test "create doesn't duplicate the author's address if they also typed it in cc" do
    author = users(:one)

    post api_orders_url, params: {
      chantier: "12345-Chantier Test", delai: "Urgent", supplier: "HGC Test Fixture",
      cc: author.email,
      items: [ { article: "ART-1", designation: "Article test", qty: 1, prix: 10.0 } ]
    }
    assert_response :success

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ author.email ], mail.cc
  end

  test "create notifies admins with the diff when modifying a previous order" do
    original = orders(:one)
    admin = users(:one)
    assert admin.admin?, "fixture user :one must be an admin for this test to be meaningful"

    post api_orders_url, params: {
      chantier: "12345-Chantier Test", delai: "Urgent", supplier: original.supplier.name,
      modifies_order_id: original.id,
      items: [
        { article: original.order_lines.first.product.reference, designation: "Article existant", qty: 3, prix: 9.99 },
        { article: "ART-99", designation: "Article ajouté", qty: 2, prix: 20.0 }
      ]
    }

    assert_response :success
    new_order = Order.order(:id).last
    assert_equal original.id, new_order.modifies_order_id

    notif = ActionMailer::Base.deliveries.find { |m| m.subject.include?(original.number) && m.subject.include?("modifiée") }
    assert notif, "an admin notification mail must be sent when modifies_order_id is provided"
    assert_includes notif.to, admin.email
    body = notif.text_part ? notif.text_part.body.to_s : notif.body.to_s
    assert_match(/Article ajouté/, body)
    assert_match(/qté 1 → 3/, body)
  end

  test "confirm_reception lets the order's author mark it received manually" do
    order = orders(:one)
    order.update!(user: users(:one))
    assert_nil order.reception_confirmed_at

    patch confirm_reception_api_order_url(order)
    assert_response :success

    order.reload
    assert order.reception_confirmed_at.present?
  end

  test "confirm_reception is idempotent — it never resets an already-confirmed timestamp" do
    order = orders(:one)
    order.update!(user: users(:one), reception_confirmed_at: 2.days.ago)
    original_timestamp = order.reception_confirmed_at

    patch confirm_reception_api_order_url(order)
    assert_response :success

    order.reload
    assert_in_delta original_timestamp, order.reception_confirmed_at, 1.second
  end

  test "confirm_reception refuses to confirm another user's order for a non-admin" do
    delete logout_url
    post login_url, params: { email: users(:two).email, password: "password123" }
    order = orders(:one)
    order.update!(user: users(:one))

    patch confirm_reception_api_order_url(order)
    assert_response :not_found
    assert_nil order.reload.reception_confirmed_at
  end

  test "confirm_reception lets an admin confirm any order, not just their own" do
    order = orders(:two)
    order.update!(user: users(:two))

    patch confirm_reception_api_order_url(order)
    assert_response :success
    assert order.reload.reception_confirmed_at.present?
  end

  test "create marks email_sent_at once the mail actually goes out" do
    post api_orders_url, params: {
      chantier: "12345-Chantier Test", delai: "Urgent", supplier: "HGC Test Fixture",
      items: [ { article: "ART-1", designation: "Article test", qty: 1, prix: 10.0 } ]
    }
    assert_response :success
    order = Order.order(:id).last
    assert order.email_sent_at.present?
  end

  test "create keeps the order but leaves email_sent_at blank when the mailer raises" do
    original = OrderMailer.method(:send_order)
    OrderMailer.define_singleton_method(:send_order) { |*, **| raise "Resend API error: 422 simulated failure" }

    begin
      post api_orders_url, params: {
        chantier: "12345-Chantier Test", delai: "Urgent", supplier: "HGC Test Fixture",
        items: [ { article: "ART-1", designation: "Article test", qty: 1, prix: 10.0 } ]
      }
    ensure
      OrderMailer.define_singleton_method(:send_order, original)
    end

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert body["order_number"].present?, "the response should still report which order was created despite the failure"

    order = Order.find_by(number: body["order_number"])
    assert order, "the order (and its lines) must survive even though the e-mail failed"
    assert_nil order.email_sent_at
  end

  test "resend retries with the exact recipients from the original attempt and marks it sent" do
    post api_orders_url, params: {
      chantier: "12345-Chantier Test", delai: "Urgent", supplier: "HGC Test Fixture",
      to: "fournisseur@example.ch", cc: "copie@induni.ch",
      items: [ { article: "ART-1", designation: "Article test", qty: 1, prix: 10.0 } ]
    }
    order = Order.order(:id).last
    order.update!(email_sent_at: nil) # simulate the original send having failed
    ActionMailer::Base.deliveries.clear

    post resend_api_order_url(order)
    assert_response :success

    order.reload
    assert order.email_sent_at.present?
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "fournisseur@example.ch" ], mail.to
    assert_includes mail.cc, "copie@induni.ch"
  end

  test "resend refuses to retry another user's order for a non-admin" do
    order = orders(:one)
    order.update!(user: users(:one), sent_to: "x@example.ch")
    delete logout_url
    post login_url, params: { email: users(:two).email, password: "password123" }

    post resend_api_order_url(order)
    assert_response :not_found
  end
end
