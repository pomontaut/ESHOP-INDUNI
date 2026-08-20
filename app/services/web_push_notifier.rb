# Sends a browser push notification to every device a user has subscribed
# from — the practical stand-in for an SMS: free (no Twilio/SMS gateway
# account needed), works the moment the user has granted notification
# permission once, and lands even if the e-shop tab isn't open.
class WebPushNotifier
  def self.notify(user, title:, body:, url: nil)
    return if user.blank?

    payload = { title: title, body: body, url: url }.to_json
    user.push_subscriptions.find_each do |subscription|
      Webpush.payload_send(
        message: payload,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key,
        vapid: {
          subject: "mailto:commande_induni_eshop@indunieshop.ch",
          public_key: Rails.application.config.x.vapid_public_key,
          private_key: Rails.application.config.x.vapid_private_key
        }
      )
    rescue Webpush::ExpiredSubscription, Webpush::InvalidSubscription
      subscription.destroy
    rescue => e
      Rails.logger.warn("WebPushNotifier: failed to notify subscription #{subscription.id}: #{e.message}")
    end
  end
end
