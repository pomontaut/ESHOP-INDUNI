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

  test "forwards the PDF attachment to Resend as base64 content" do
    # payload(mail) used to only ever build {from, to, subject, html, text} —
    # the attachment itself was silently dropped, so suppliers never actually
    # received the bon de commande PDF via the real "Envoyer la commande" flow
    # (only the client-side "Ouvrir dans Outlook" .eml fallback attached one).
    mail = OrderMailer.send_order(orders(:one), "%PDF-1.4 fake pdf content").message

    payload = build_delivery.send(:payload, mail)

    assert payload[:attachments].present?
    attachment = payload[:attachments].first
    assert_equal "commande_#{orders(:one).number}.pdf", attachment[:filename]
    assert_equal "%PDF-1.4 fake pdf content", Base64.strict_decode64(attachment[:content])
    # Without this, Outlook guesses the MIME type wrong and renames the
    # attachment to "....pdf.txt" even though the bytes are a real PDF.
    assert_equal "application/pdf", attachment[:content_type]
  end

  test "forwards Cc addresses to Resend" do
    # payload(mail) never read mail.cc at all — every Cc address (e.g. the
    # order author, always added so they get proof of what was sent) was
    # silently dropped on every real send through Resend, even though it
    # showed up correctly in the local letter_opener preview.
    mail = OrderMailer.send_order(orders(:one), nil, cc: "author@induni.ch, other@induni.ch").message

    payload = build_delivery.send(:payload, mail)

    assert_equal [ "author@induni.ch", "other@induni.ch" ], payload[:cc]
  end

  test "omits the cc key when the mail has no Cc" do
    mail = OrderMailer.send_order(orders(:one), nil).message
    payload = build_delivery.send(:payload, mail)
    assert_not payload.key?(:cc)
  end

  test "forwards the read-receipt headers to Resend" do
    mail = OrderMailer.send_order(orders(:one), nil, read_receipt_to: "author@induni.ch").message

    payload = build_delivery.send(:payload, mail)

    assert_equal "author@induni.ch", payload[:headers]["Disposition-Notification-To"]
    assert_equal "author@induni.ch", payload[:headers]["Return-Receipt-To"]
  end

  test "omits the headers key when no custom header is set" do
    mail = OrderMailer.send_order(orders(:one), nil).message
    payload = build_delivery.send(:payload, mail)
    assert_not payload.key?(:headers)
  end

  test "omits the attachments key when the mail has no attachment" do
    mail = Mail.new do
      from    "induni@example.com"
      to      "supplier@example.com"
      subject "Test"
      text_part { body "plain body" }
      html_part { content_type "text/html; charset=UTF-8"; body "<p>html body</p>" }
    end

    payload = build_delivery.send(:payload, mail)

    assert_not payload.key?(:attachments)
  end
end
