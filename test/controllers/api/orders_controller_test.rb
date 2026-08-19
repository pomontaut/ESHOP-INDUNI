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
    assert_redirected_to login_path
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
    assert_equal [ "technicien@induni.ch" ], mail.cc, "the malformed cc entry must be dropped, not raise"
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
end
