require "test_helper"

class ResendDeliveryMethodTest < ActiveSupport::TestCase
  def build_delivery
    ResendDeliveryMethod.new(api_key: "test-key")
  end

  test "extracts html and text bodies from a simple multipart/alternative mail" do
    mail = Mail.new do
      from    "induni@example.com"
      to      "supplier@example.com"
      subject "Test"
      text_part { body "plain body" }
      html_part { content_type "text/html; charset=UTF-8"; body "<p>html body</p>" }
    end

    payload = build_delivery.send(:payload, mail)

    assert_equal "plain body", payload[:text]
    assert_equal "<p>html body</p>", payload[:html]
  end

  test "extracts html and text bodies from OrderMailer#send_order with a PDF attached" do
    # ActionMailer wraps a multipart/alternative (html+text) body one level
    # deeper inside multipart/mixed once an attachment is present — this is
    # the exact structure that reached production and made Resend reject the
    # request with "Missing `html` or `text` field" (422).
    mail = OrderMailer.send_order(orders(:one), "%PDF-1.4 fake pdf content").message

    assert_equal "multipart/mixed", mail.mime_type
    assert mail.parts.first.multipart?, "the body must be nested one level deep once there's an attachment"

    payload = build_delivery.send(:payload, mail)

    assert payload[:html].present?, "html part must be found even when nested under multipart/mixed"
    assert payload[:text].present?, "text part must be found even when nested under multipart/mixed"
  end

  test "extracts a single html body with no text alternative and an attachment" do
    mail = Mail.new do
      from    "induni@example.com"
      to      "supplier@example.com"
      subject "Commande BC-124"
      content_type "text/html; charset=UTF-8"
      body "<p>only html</p>"
      add_file filename: "commande.pdf", content: "%PDF-1.4 fake content"
    end

    payload = build_delivery.send(:payload, mail)

    assert_equal "<p>only html</p>", payload[:html]
  end
end
