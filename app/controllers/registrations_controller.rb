class RegistrationsController < ApplicationController
  skip_before_action :require_login

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    expected_code = ENV["REGISTRATION_CODE"].presence
    submitted_code = params[:registration_code].to_s
    if expected_code && !ActiveSupport::SecurityUtils.secure_compare(submitted_code, expected_code)
      @user.errors.add(:base, "Code d'invitation invalide")
      return render :new, status: :unprocessable_entity
    end

    if @user.save
      session[:user_id] = @user.id
      redirect_to "/catalogue.html", notice: "Bienvenue #{@user.full_name} ! Votre compte a été créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :email, :password, :password_confirmation, :first_name, :last_name, :job_function, :sector
    )
  end
end
