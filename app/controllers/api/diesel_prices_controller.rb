class Api::DieselPricesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    render json: DieselPrice.ordered.map { |d|
      { weekStart: d.week_start.iso8601, price: d.price.to_f, surchargePct: d.surcharge_pct.round(2) }
    }
  end

  # Un admin saisit la valeur CHF/litre de la semaine ASTAG en cours — pas de
  # scraping automatique fiable disponible (voir discussion), donc mise à
  # jour manuelle hebdomadaire côté admin. upsert par semaine ISO (lundi)
  # pour permettre de corriger la valeur si besoin sans doublon.
  def create
    return render json: { error: "Réservé aux administrateurs." }, status: :forbidden unless current_user&.admin?

    price = params[:price].to_f
    return render json: { error: "Prix invalide." }, status: :unprocessable_entity if price <= 0

    week_start = Date.current.beginning_of_week(:monday)
    entry = DieselPrice.find_or_initialize_by(week_start: week_start)
    entry.price = price
    if entry.save
      render json: { weekStart: entry.week_start.iso8601, price: entry.price.to_f, surchargePct: entry.surcharge_pct.round(2) }
    else
      render json: { error: entry.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end
end
