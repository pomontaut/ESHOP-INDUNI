class Api::SessionsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token

  def me
    if current_user
      render json: { logged_in: true, admin: current_user.admin? }
    else
      render json: { logged_in: false, admin: false }
    end
  end
end
