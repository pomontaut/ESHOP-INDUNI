# Voir AppEnvironment / StagingMailInterceptor : en staging (APP_ENV=staging),
# aucun e-mail ne part vers de vrais destinataires. Enregistré après le
# chargement de l'application (les classes de app/ ne sont pas encore
# autochargeables ici).
if ENV["APP_ENV"] == "staging"
  Rails.application.config.after_initialize do
    ActionMailer::Base.register_interceptor(StagingMailInterceptor)
  end
end
