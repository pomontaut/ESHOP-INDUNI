class Admin::UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: [ :edit, :update, :destroy, :resend_welcome ]

  def index
    @users = User.order(:last_name, :first_name)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if grants_admin? && !valid_admin_code?
      @user.errors.add(:base, "Code de confirmation administrateur invalide ou manquant.")
      return render :new, status: :unprocessable_entity
    end
    temporary_password = params.dig(:user, :password).to_s
    if @user.save
      begin
        UserMailer.welcome(@user, temporary_password).deliver_now
        redirect_to admin_users_path, notice: "Utilisateur #{@user.full_name} créé. Un email avec ses identifiants lui a été envoyé."
      rescue => e
        redirect_to admin_users_path, alert: "Utilisateur #{@user.full_name} créé, mais l'email n'a pas pu être envoyé : #{e.message}"
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    attrs = user_params
    attrs.delete(:password) if attrs[:password].blank?
    promoting_to_admin = ActiveModel::Type::Boolean.new.cast(attrs[:admin]) && !@user.admin?
    if promoting_to_admin && !valid_admin_code?
      @user.errors.add(:base, "Code de confirmation administrateur invalide ou manquant.")
      return render :edit, status: :unprocessable_entity
    end
    if @user.update(attrs)
      redirect_to admin_users_path, notice: "Droits de #{@user.full_name} mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def resend_welcome
    new_password = SecureRandom.hex(6)
    @user.update!(password: new_password, must_change_password: true)
    UserMailer.welcome(@user, new_password).deliver_now
    redirect_to admin_users_path, notice: "Nouveau mot de passe envoyé à #{@user.email}."
  rescue => e
    redirect_to admin_users_path, alert: "Erreur d'envoi de l'email : #{e.message}"
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "Vous ne pouvez pas supprimer votre propre compte."
    else
      @user.destroy
      redirect_to admin_users_path, notice: "Utilisateur supprimé."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # Un utilisateur ne peut jamais devenir administrateur par lui-même : la
  # promotion passe forcément par un administrateur existant, ET par ce code
  # (ADMIN_PROMOTION_CODE), pour empêcher qu'une session admin compromise —
  # ou manipulée via une IA/un script — ne suffise seule à créer un nouvel
  # accès administrateur. Si aucun code n'est configuré côté serveur, la
  # promotion reste bloquée plutôt que d'être silencieusement autorisée.
  def valid_admin_code?
    expected_code = ENV["ADMIN_PROMOTION_CODE"].presence
    return false unless expected_code
    ActiveSupport::SecurityUtils.secure_compare(params[:admin_confirmation_code].to_s, expected_code)
  end

  def grants_admin?
    ActiveModel::Type::Boolean.new.cast(user_params[:admin])
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Accès réservé aux administrateurs."
    end
  end

  def user_params
    permitted = params.require(:user).permit(
      :email, :password, :first_name, :last_name, :job_function, :sector, :phone,
      :admin, :must_change_password,
      :can_read, :can_create_orders, :can_modify_orders, :can_create_users,
      :can_import_quote, :can_generic_order,
      :can_view_dashboard, :can_view_analysis, :can_view_market_indices, :can_view_intelligence_buying,
      :can_view_nomenclature,
      :order_limit, :approver_email,
      :chantier_access_scope,
      allowed_suppliers: []
    )
    # The form always submits a hidden "" alongside the checkboxes so an
    # all-unchecked submission still sends the param — strip it, or an admin
    # leaving every catalog box unchecked (meaning "no manual restriction")
    # would instead save allowed_suppliers: [""], which User#effective_visible_suppliers
    # would previously treat as "restricted to nothing" — every catalog empty.
    permitted[:allowed_suppliers] = permitted[:allowed_suppliers].reject(&:blank?) if permitted.key?(:allowed_suppliers)
    permitted
  end
end
