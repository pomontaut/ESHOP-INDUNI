class ReplaceHgcReductionsPvcKgr < ActiveRecord::Migration[8.0]
  # Réductions PVC dur KGR HGC remplacées à la demande du propriétaire par les 13 références du
  # catalogue HGC (100095630-638, 100099793, 100101816, 100101862-863 : catalog_products.json).
  # Une ancienne référence déjà commandée (clé étrangère order_lines) est conservée mais sortie du
  # catalogue (sans famille ni équivalence). Équivalences Canplast SN4 à diamètres IDENTIQUES
  # seulement (200/125, 250/200) : l'ancien lien 125/100 ↔ Canplast 125/110 était faux, retiré.
  OLD_REFERENCES = %w[100098830 100098832 100098834].freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    scope = Product.where(supplier_id: hgc.id, reference: OLD_REFERENCES)
    ordered_ids = OrderLine.where(product_id: scope.select(:id)).distinct.pluck(:product_id)
    scope.where.not(id: ordered_ids).delete_all
    Product.where(id: ordered_ids).update_all(famille: nil, sous_famille: nil, sous_sous_famille: nil, equivalence_key: nil)

    canplast = Supplier.find_by(name: "Canplast")
    Product.where(supplier_id: canplast.id, reference: "LDR125110").update_all(equivalence_key: nil) if canplast
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
