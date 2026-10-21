# Reporting articles des commandes e-shop.
# - `articles` : Analyse achat de l'e-shop (utilisateur connecté avec le droit
#   « Analyse », périmètre = commandes qui lui sont visibles) ;
# - `sla`      : export lu par SLA (fiche fournisseur), via jeton serveur à
#   serveur (ENV["SLA_REPORTING_TOKEN"], en-tête Authorization: Bearer …).
#   Prix confidentiels toujours masqués.
class Api::ReportingController < ApplicationController
  skip_before_action :require_login, only: :sla

  def articles
    unless current_user.admin? || current_user.effective_can_view_analysis?
      return render json: { error: "Accès réservé à l'Analyse achat" }, status: :forbidden
    end

    render json: ArticleReport.new(scope: Order.visible_to(current_user), **filters, show_confidential: true)
  end

  def sla
    expected = ENV["SLA_REPORTING_TOKEN"].to_s
    given = request.authorization.to_s.delete_prefix("Bearer ").strip
    return render json: { error: "Export SLA non configuré" }, status: :service_unavailable if expected.blank?
    unless given.present? && ActiveSupport::SecurityUtils.secure_compare(given, expected)
      return render json: { error: "Jeton invalide" }, status: :unauthorized
    end

    render json: ArticleReport.new(scope: Order.all, **filters, show_confidential: false)
  end

  private

  def filters
    { from: params[:from], to: params[:to], supplier: params[:supplier] }
  end
end
