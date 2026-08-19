require "net/http"
require "json"

# ActionMailer delivery method that sends through Resend's HTTPS API
# (https://resend.com/docs/api-reference/emails/send-email) instead of SMTP.
# Some hosts (Railway among them) block outbound SMTP ports, which makes
# ActionMailer's :smtp delivery hang until Net::OpenTimeout — the API runs
# over plain HTTPS (443), which is never blocked.
class ResendDeliveryMethod
  def initialize(settings)
    @api_key = settings[:api_key]
  end

  def deliver!(mail)
    uri = URI("https://api.resend.com/emails")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    # A mail with a PDF attachment pushes the request body from a few KB to
    # potentially several hundred KB (base64-encoded) — 5s was tight enough
    # on its own to cause spurious Net::ReadTimeout failures on real orders
    # even before attachments were forwarded at all (see payload below).
    http.open_timeout = 15
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"
    request.body = payload(mail).to_json

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      raise "Resend API error: #{response.code} #{response.body}"
    end

    response
  end

  private

  def payload(mail)
    {
      from: mail[:from].to_s,
      to: Array(mail.to),
      subject: mail.subject,
      html: part_body(mail, "text/html"),
      text: part_body(mail, "text/plain"),
      attachments: attachments_payload(mail)
    }.compact
  end

  # `mail.attachments` (Mail::AttachmentsList) never included the PDF
  # attached by OrderMailer#send_order in the actual Resend request — only
  # the html/text body ever reached the API, so suppliers never received the
  # bon de commande PDF via the real order-sending flow.
  def attachments_payload(mail)
    return nil if mail.attachments.empty?
    mail.attachments.map { |attachment| { filename: attachment.filename, content: Base64.strict_encode64(attachment.body.decoded) } }
  end

  # A mail with an attachment is wrapped as multipart/mixed containing the
  # actual body (itself multipart/alternative when both an HTML and a text
  # template exist) alongside the attachment part, so the html/text parts can
  # be nested one or more levels deep — not just direct children of `mail`.
  def part_body(mail, content_type)
    if mail.multipart?
      find_part_body(mail, content_type)
    elsif mail.content_type&.start_with?(content_type)
      mail.body.decoded
    end
  end

  def find_part_body(container, content_type)
    container.parts.each do |part|
      if part.multipart?
        found = find_part_body(part, content_type)
        return found if found
      elsif part.content_type&.start_with?(content_type) && !part.attachment?
        return part.body.decoded
      end
    end
    nil
  end
end
