class CopyLeubaHiagBoisFamiliesToHgCommerciale < ActiveRecord::Migration[8.0]
  # Copier-coller des familles de bois de Leuba HIAG (famille « Bois &
  # Coffrage » et toutes ses sous-familles) chez HG COMMERCIALE : mêmes
  # références, désignations, prix et classement. N'écrase jamais un article
  # HG COMMERCIALE déjà présent avec la même référence, et ne copie pas
  # l'equivalence_key (ces articles ne sont pas des équivalents Canplast).
  FAMILLE = "Bois & Coffrage".freeze
  COPIED_ATTRS = %w[
    name descriptif unit_price unite famille sous_famille sous_sous_famille
    icone image poids_kg prix_m2 qte_palette stock_status
  ].freeze

  def up
    leuba = Supplier.find_by(name: "Leuba HIAG")
    hgc   = Supplier.find_by(name: "HG COMMERCIALE")
    return unless leuba && hgc

    existing = Product.where(supplier_id: hgc.id).pluck(:reference).to_set
    Product.where(supplier_id: leuba.id, famille: FAMILLE).find_each do |source|
      next if existing.include?(source.reference)

      Product.create!(source.attributes.slice(*COPIED_ATTRS).merge(supplier: hgc, reference: source.reference, manually_added: false))
    end
  end

  def down
    # Non réversible proprement : no-op délibéré.
  end
end
