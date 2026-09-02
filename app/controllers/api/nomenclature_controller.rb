# Backlog of catalog products added from a devis import without a known
# family/sub-family (see Api::DevisImportsController#confirm_products) —
# reserved for buyers ("profil achats", proxied here by can_import_quote)
# and admins to file them under the right catalog category.
class Api::NomenclatureController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_nomenclature_permission

  def index
    products = Product.where(needs_classification: true).includes(:supplier).order(:created_at)
    render json: products.map { |p|
      {
        id:              p.id,
        catalog:         p.supplier&.name,
        article:         p.reference,
        designation:     p.name,
        prix:            p.unit_price.to_f,
        unite:           p.unite,
        createdAt:       p.created_at.strftime("%d.%m.%Y"),
        responsableAchat: p.supplier&.responsable_achat
      }
    }
  end

  def update
    product = Product.find(params[:id])
    famille = params[:famille].to_s.strip
    return render json: { error: "Famille manquante." }, status: :unprocessable_entity if famille.blank?

    product.update!(
      famille:              famille,
      sous_famille:         params[:sousFamille].to_s.strip.presence,
      sous_sous_famille:    "__DIRECT__",
      needs_classification: false
    )
    render json: { success: true }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Article introuvable." }, status: :not_found
  end

  private

  def require_nomenclature_permission
    unless current_user&.admin? || current_user&.effective_can_import_quote?
      render json: { error: "Accès réservé aux profils achats et administrateur." }, status: :forbidden
    end
  end
end
