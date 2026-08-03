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
    http.open_timeout = 5
    http.read_timeout = 5

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
      text: part_body(mail, "text/plain")
    }.compact
  end

  def part_body(mail, content_type)
    if mail.multipart?
      part = mail.body.parts.find { |p| p.content_type&.start_with?(content_type) }
      part&.body&.decoded
    elsif mail.content_type&.start_with?(content_type)
      mail.body.decoded
    end
  end
end
