class Admin::ChantiersController < ApplicationController
  before_action :require_admin
  before_action :set_chantier, only: [ :edit, :update, :destroy ]

  def index
    @chantiers = Chantier.order(:nom)
    if params[:q].present?
      @chantiers = @chantiers.where("nom LIKE :q OR ville LIKE :q OR npa LIKE :q", q: "%#{params[:q]}%")
    end
  end

  def new
    @chantier = Chantier.new
  end

  def create
    @chantier = Chantier.new(chantier_params)
    if @chantier.save
      redirect_to admin_chantiers_path, notice: "Chantier #{@chantier.nom} créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @chantier.update(chantier_params)
      redirect_to admin_chantiers_path, notice: "Chantier #{@chantier.nom} mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @chantier.destroy
    redirect_to admin_chantiers_path, notice: "Chantier supprimé."
  end

  private

  def set_chantier
    @chantier = Chantier.find(params[:id])
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Accès réservé aux administrateurs."
    end
  end

  def chantier_params
    params.require(:chantier).permit(
      :nom, :adresse, :npa, :ville, :canton, :secteur, :contraintes_acces, :carte_interactive, :consortium,
      :technicien, :natel_technicien, :email_technicien,
      :contremaitre, :natel_contremaitre, :email_contremaitre,
      :chef_equipe, :natel_chef_equipe, :email_chef_equipe,
      :conducteur_travaux, :natel_conducteur_travaux, :email_conducteur_travaux
    )
  end
end
