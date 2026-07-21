class ChantiersController < ApplicationController
  def index
    @chantiers = Chantier.visible_to(current_user).order(:nom)
    @chantiers = @chantiers.where("nom LIKE ?", "%#{params[:q]}%") if params[:q].present?
  end

  def show
    @chantier = Chantier.visible_to(current_user).find(params[:id])
  end
end
