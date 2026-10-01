class ProjetsController < ApplicationController
  before_action :require_achat_access
  before_action :set_projet, only: [ :show, :edit, :update, :destroy ]

  def new
    @projet = Projet.new(responsable: current_user)
  end

  def create
    @projet = Projet.new(projet_params)
    if @projet.save
      redirect_to @projet, notice: "Projet #{@projet.nom} créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @briques = PortailAchat.briques(helpers)
  end

  def edit; end

  def update
    if @projet.update(projet_params)
      redirect_to @projet, notice: "Projet mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @projet.destroy
    redirect_to portail_path, notice: "Projet supprimé."
  end

  private

  def set_projet = @projet = Projet.find(params[:id])

  def projet_params
    params.require(:projet).permit(:nom, :numero, :chantier_id, :responsable_id, :statut, :description)
  end
end
