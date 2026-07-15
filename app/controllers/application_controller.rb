class ApplicationController < ActionController::Base
  before_action :require_login

  private

  def require_login
    unless current_user
      redirect_to login_path, alert: "Veuillez vous connecter pour accéder à cette page."
    end
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  helper_method :current_user
end
