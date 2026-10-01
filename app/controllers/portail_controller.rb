class PortailController < ApplicationController
  before_action :require_achat_access

  def index
    @briques = PortailAchat.briques(helpers)
    @projets = Projet.en_cours.includes(:chantier, :responsable).order(:nom)
  end
end
