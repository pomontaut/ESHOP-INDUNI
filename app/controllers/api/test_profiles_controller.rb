# Environnement test réservé aux administrateurs : permet de voir le catalogue
# avec le seul bandeau d'un profil chantier (contremaître ou conducteur de
# travaux), sans droits d'administration. Purement visuel : le compte reste
# administrateur côté serveur, et « Quitter » rétablit la vue normale.
class Api::TestProfilesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_admin

  PROFILES = [ "Contremaître", "Conducteur de travaux" ].freeze

  def self.active_profile(session, user)
    profile = session[:test_profile]
    profile if user&.admin? && PROFILES.include?(profile)
  end

  def create
    profile = params[:profile].to_s
    return render json: { error: "Profil inconnu." }, status: :unprocessable_entity unless PROFILES.include?(profile)

    session[:test_profile] = profile
    render json: { test_profile: profile }
  end

  def destroy
    session.delete(:test_profile)
    render json: { test_profile: nil }
  end

  private

  def require_admin
    render json: { error: "Réservé aux administrateurs." }, status: :forbidden unless current_user&.admin?
  end
end
