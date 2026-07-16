class Admin::UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: [:edit, :update, :destroy]

  def index
    @users = User.order(:last_name, :first_name)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to admin_users_path, notice: "Utilisateur #{@user.full_name} créé avec succès."
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
      :email, :password, :first_name, :last_name, :job_function,
      :admin, :must_change_password,
      :can_read, :can_create_orders, :can_modify_orders, :can_create_users,
      :order_limit, :approver_email,
      allowed_suppliers: []
    )
  end
end
