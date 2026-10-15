# En staging, aucun e-mail ne doit atteindre un vrai destinataire (fournisseurs,
# approbateurs, utilisateurs). Tout est redirigé vers STAGING_MAIL_TO (une ou
# plusieurs adresses séparées par des virgules) ; sans cette variable, rien
# n'est envoyé.
class StagingMailInterceptor
  def self.delivering_email(message)
    original = [ message.to, message.cc ].flatten.compact.join(", ")
    target = ENV["STAGING_MAIL_TO"].to_s.split(",").map(&:strip).reject(&:blank?)
    message.subject = "[STAGING] #{message.subject}"
    if target.empty?
      message.perform_deliveries = false
    else
      message.to  = target
      message.cc  = nil
      message.bcc = nil
      message.header["X-Original-Recipients"] = original
    end
  end
end
