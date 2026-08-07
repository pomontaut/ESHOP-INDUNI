class ChangePasswordController < ApplicationController
  def edit
  end

  def update
    if params[:password] != params[:password_confirmation]
      flash.now[:alert] = "Les mots de passe ne correspondent pas."
      return render :edit, status: :unprocessable_entity
    end

    if params[:password].to_s.length < 8
      flash.now[:alert] = "Le mot de passe doit contenir au moins 8 caractères."
      return render :edit, status: :unprocessable_entity
    end

    current_user.update!(password: params[:password], must_change_password: false)
    redirect_to "/catalogue.html", notice: "Mot de passe mis à jour. Bienvenue #{current_user.full_name} !"
  end
end
