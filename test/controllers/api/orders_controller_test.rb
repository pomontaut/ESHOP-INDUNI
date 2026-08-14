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
end
