class UserMailer < ApplicationMailer
  def welcome(user, temporary_password)
    @user               = user
    @temporary_password = temporary_password
    @login_url          = Rails.application.routes.url_helpers.login_url(
      host: default_url_options[:host]
    )
    mail(to: user.email, subject: "Bienvenue sur l'e-shop Induni — vos identifiants de connexion")
  end
end
