class Api::CanplastSurchargesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    render json: CanplastSurcharge.ordered.map { |s|
      { codes: s.codes, label: s.label, effectiveDate: s.effective_date.iso8601, surchargePct: s.surcharge_pct.to_f, source: s.source }
    }
  end

  # Ajoute une nouvelle date de hausse (ou baisse) pour un groupe d'articles
  # déjà suivi — pas de scraping automatique disponible pour Canplast non
  # plus (avis envoyés par PDF ponctuel, sans URL stable), donc saisie admin
  # à chaque nouvel avis reçu.
  def create
    return render json: { error: "Réservé aux administrateurs." }, status: :forbidden unless current_user&.admin?

    codes = params[:codes].to_s.strip
    label = params[:label].to_s.strip
    effective_date = params[:effective_date].presence || Date.current.iso8601
    surcharge_pct = params[:surcharge_pct]

    return render json: { error: "Groupe d'articles manquant." }, status: :unprocessable_entity if codes.blank? || label.blank?

    entry = CanplastSurcharge.find_or_initialize_by(codes: codes, effective_date: effective_date)
    entry.label = label
    entry.surcharge_pct = surcharge_pct
    entry.source = params[:source].presence || "Saisie manuelle"
    if entry.save
      render json: { codes: entry.codes, label: entry.label, effectiveDate: entry.effective_date.iso8601, surchargePct: entry.surcharge_pct.to_f, source: entry.source }
    else
      render json: { error: entry.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end
end
