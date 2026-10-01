class SeanceLancementsController < ApplicationController
  before_action :require_achat_access
  before_action :set_projet

  def show
    redirect_to edit_projet_seance_lancement_path(@projet)
  end

  def edit
    @seance = @projet.seance_lancement_or_build
  end

  def update
    @seance = @projet.seance_lancement_or_build
    if @seance.update(seance_params)
      redirect_to @projet, notice: "Séance de lancement enregistrée."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_projet = @projet = Projet.find(params[:projet_id])

  def seance_params
    params.require(:seance_lancement).permit(
      :date_seance, :lieu, :participants, :budget_cible, :perimetre,
      :strategie_achat, :risques, :decisions, :actions, :realisee
    )
  end
end
