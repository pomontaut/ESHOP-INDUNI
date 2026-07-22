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
    temporary_password = params.dig(:user, :password).to_s
    if @user.save
      UserMailer.welcome(@user, temporary_password).deliver_later
      redirect_to admin_users_path, notice: "Utilisateur #{@user.full_name} créé. Un email avec ses identifiants lui a été envoyé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    attrs = user_params
    attrs.delete(:password) if attrs[:password].blank?
    if @user.update(attrs)
      redirect_to admin_users_path, notice: "Droits de #{@user.full_name} mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def resend_welcome
    new_password = SecureRandom.hex(6)
    @user.update!(password: new_password, must_change_password: true)
    UserMailer.welcome(@user, new_password).deliver_later
    redirect_to admin_users_path, notice: "Nouveau mot de passe envoyé à #{@user.email}."
  rescue => e
    redirect_to admin_users_path, alert: "Erreur : #{e.message}"
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

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Accès réservé aux administrateurs."
    end
  end

  def user_params
    params.require(:user).permit(
      :email, :password, :first_name, :last_name, :job_function, :sector,
      :admin, :must_change_password,
      :can_read, :can_create_orders, :can_modify_orders, :can_create_users,
      :order_limit, :approver_email,
      allowed_suppliers: []
    )
  end
end
