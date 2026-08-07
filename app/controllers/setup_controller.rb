class SetupController < ApplicationController
  skip_before_action :require_login

  def admin
    token = ENV["SETUP_TOKEN"].presence
    unless token && params[:token] == token
      return render plain: "Non autorisé.", status: :unauthorized
    end

    email    = ENV["ADMIN_EMAIL"].presence    || "pomontaut@induni.ch"
    password = ENV["ADMIN_PASSWORD"].presence
    unless password
      return render plain: "Variable ADMIN_PASSWORD manquante.", status: :unprocessable_entity
    end

    user = User.find_or_initialize_by(email: email)
    user.first_name         = ENV["ADMIN_FIRST_NAME"].presence || "Admin"
    user.last_name          = ENV["ADMIN_LAST_NAME"].presence  || "Induni"
    user.password           = password
    user.admin              = true
    user.must_change_password = false

    if user.save
      render plain: "OK — compte admin créé/mis à jour : #{email}"
    else
      render plain: "Erreur : #{user.errors.full_messages.join(', ')}", status: :unprocessable_entity
    end
  end
end
