class ReplaceHgcTuyauxCompactStandardPvc < ActiveRecord::Migration[8.0]
  # Tuyaux PVC « compact standard » HGC remplacés à la demande du propriétaire par 35 références du
  # catalogue HGC (catalog_products.json), reclassées par rigidité SN2/SN4/SN8. Les anciennes
  # 100022512 et 100063110-113 sont reprises dans le nouveau jeu (mise à jour par catalog:seed).
  # Une ancienne référence déjà commandée (clé étrangère order_lines) est conservée mais sortie du
  # catalogue (sans famille ni équivalence). Équivalences Canplast : SN, diamètre ET longueur
  # strictement identiques (réécrites par catalog:seed d'après le JSON).
  OLD_REFERENCES = %w[
    100099736 100099737 100099738 100099739 100099800 100099801 100099802 100099284
    100099803 100099804 100099805 100099806 100099807 100099808
  ].freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    scope = Product.where(supplier_id: hgc.id, reference: OLD_REFERENCES)
    ordered_ids = OrderLine.where(product_id: scope.select(:id)).distinct.pluck(:product_id)
    scope.where.not(id: ordered_ids).delete_all
    Product.where(id: ordered_ids).update_all(famille: nil, sous_famille: nil, sous_sous_famille: nil, equivalence_key: nil)
    canplast = Supplier.find_by(name: "Canplast")
    Product.where(supplier_id: canplast.id, equivalence_key: OLD_REFERENCES).update_all(equivalence_key: nil) if canplast
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
