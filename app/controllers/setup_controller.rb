class SetupController < ApplicationController
  skip_before_action :require_login

  SETUP_TOKEN = ENV.fetch("SETUP_TOKEN", nil)

  def create_admin
    unless SETUP_TOKEN.present? && params[:token] == SETUP_TOKEN
      render plain: "Unauthorized", status: :unauthorized and return
    end

    if User.exists?(email: "pomontaut@induni.ch")
      render plain: "User already exists" and return
    end

    user = User.create!(
      email: "pomontaut@induni.ch",
      password: params[:password],
      password_confirmation: params[:password],
      first_name: "Pascal",
      last_name: "Omontaut",
      admin: true
    )
    render plain: "Admin created: #{user.email}"
  rescue => e
    render plain: "Error: #{e.message}", status: :unprocessable_entity
  end
end
