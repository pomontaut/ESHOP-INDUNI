# Mode test administrateur : bascule l'affichage vers le bandeau d'un profil
# d'exploitation (Contremaître, Conducteur de travaux) pour le tester, puis permet
# d'en sortir. Appelé en fetch() depuis catalogue.html (pas de jeton CSRF).
class Api::PreviewsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_real_admin

  def create
    profile = params[:profile].to_s
    unless User::PREVIEW_PROFILES.key?(profile)
      return render json: { error: "Profil inconnu" }, status: :unprocessable_entity
    end
    session[:preview_profile] = profile
    render json: { preview_profile: profile, preview_label: User::PREVIEW_PROFILES[profile][:label] }
  end

  def destroy
    session.delete(:preview_profile)
    render json: { preview_profile: nil }
  end

  private

  def require_real_admin
    return if current_user&.admin?
    render json: { error: "Accès réservé aux administrateurs" }, status: :forbidden
  end
end
