class ReplaceHgcTuyauxDrainagePvcCompact < ActiveRecord::Migration[8.0]
  # Tuyaux de drainage PVC compact HGC remplacés à la demande du propriétaire par 8 références du
  # catalogue HGC (100063171-174, 100036831/833, 100072432-433), reclassées par rigidité SN2/SN4/SN8
  # (catalog_products.json). Une ancienne référence déjà commandée (clé étrangère order_lines) est
  # conservée mais sortie du catalogue (sans famille ni équivalence). Équivalences Canplast LD-TP :
  # diamètre ET SN identiques seulement (125 SN4, 200/250/400 SN2).
  OLD_REFERENCES = %w[100036836 100036839 100092515 100092516].freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    scope = Product.where(supplier_id: hgc.id, reference: OLD_REFERENCES)
    ordered_ids = OrderLine.where(product_id: scope.select(:id)).distinct.pluck(:product_id)
    scope.where.not(id: ordered_ids).delete_all
    Product.where(id: ordered_ids).update_all(famille: nil, sous_famille: nil, sous_sous_famille: nil, equivalence_key: nil)
    # Les liens Canplast vers les anciennes références sont réécrits par catalog:seed (clé du JSON).
    canplast = Supplier.find_by(name: "Canplast")
    Product.where(supplier_id: canplast.id, equivalence_key: OLD_REFERENCES).update_all(equivalence_key: nil) if canplast
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
