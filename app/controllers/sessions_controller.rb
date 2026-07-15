class SessionsController < ApplicationController
  skip_before_action :require_login

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.downcase)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      if user.must_change_password?
        redirect_to change_password_path, notice: "Bienvenue ! Veuillez choisir votre mot de passe personnel."
      else
        redirect_to '/catalogue.html', notice: "Bienvenue #{user.full_name} !"
      end
    else
      flash.now[:alert] = "Email ou mot de passe incorrect."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "Vous êtes déconnecté."
  end
end
