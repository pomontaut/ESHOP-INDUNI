# Environnement de test (« staging ») : même code que la production mais une
# base et un service Railway séparés, repérés par APP_ENV=staging. Garde-fous :
# les e-mails ne partent jamais vers les vrais fournisseurs (voir
# StagingMailInterceptor), la relance automatique est coupée et un bandeau
# rouge s'affiche dans l'e-shop.
module AppEnvironment
  def self.staging?
    ENV["APP_ENV"] == "staging"
  end

  def self.name
    staging? ? "staging" : "production"
  end
end
