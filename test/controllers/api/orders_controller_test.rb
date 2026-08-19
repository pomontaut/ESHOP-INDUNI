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
end
