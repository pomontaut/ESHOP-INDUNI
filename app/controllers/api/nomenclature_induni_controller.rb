# Bibliothèque d'articles Induni (onglet « Nomenclature Induni ») :
# réservée aux administrateurs. Ne renvoie aucun prix.
class Api::NomenclatureInduniController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_admin

  def index
    keys = NomenclatureEntry.catalog_keys
    render json: NomenclatureEntry.ordered.map { |e|
      {
        id:                  e.id,
        nCompta:             e.n_compta,
        segmentation1:       e.segmentation1,
        segmentation2:       e.segmentation2,
        segmentation3:       e.segmentation3,
        induniReference:     e.induni_reference,
        induniDesignation:   e.induni_designation,
        supplierName:        e.supplier_name,
        supplierReference:   e.supplier_reference,
        supplierDesignation: e.supplier_designation,
        priceUnit:           e.price_unit,
        searchKeywords:      e.search_keywords,
        inCatalog:           keys.include?([ e.supplier_name, e.supplier_reference ])
      }
    }
  end

  private

  def require_admin
    render json: { error: "Accès réservé aux administrateurs." }, status: :forbidden unless current_user&.admin?
  end
end
