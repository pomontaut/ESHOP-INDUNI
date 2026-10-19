class Api::FavoritesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    render json: current_user.favorites.order(:catalog, :created_at)
  end

  # Bascule : crée le favori s'il n'existe pas, le supprime sinon.
  def toggle
    attrs = { catalog: params[:catalog].to_s, article: params[:article].to_s, designation: params[:designation].to_s }
    return render json: { error: "catalogue et article requis" }, status: :unprocessable_entity if attrs[:catalog].blank? || attrs[:article].blank?

    fav = current_user.favorites.find_by(attrs)
    if fav
      fav.destroy
      render json: { favorite: false }
    else
      current_user.favorites.create!(attrs)
      render json: { favorite: true }
    end
  end
end
