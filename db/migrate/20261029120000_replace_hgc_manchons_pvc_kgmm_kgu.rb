class ReplaceHgcManchonsPvcKgmmKgu < ActiveRecord::Migration[8.0]
  # Manchons doubles KGMM et coulissants KGU HGC remplacés à la demande du propriétaire par les
  # références du catalogue HGC (100095626-628, 100099902-904 ; 100095599, 100095620-624, 100024006,
  # 100095625 : catalog_products.json). Une ancienne référence déjà commandée (clé étrangère
  # order_lines) est conservée mais sortie du catalogue (sans famille ni équivalence).
  OLD_REFERENCES = %w[
    100092562 100092563 100092564 100092565 100023699
    100098824 100098825 100098826 100098828
  ].freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    scope = Product.where(supplier_id: hgc.id, reference: OLD_REFERENCES)
    ordered_ids = OrderLine.where(product_id: scope.select(:id)).distinct.pluck(:product_id)
    scope.where.not(id: ordered_ids).delete_all
    Product.where(id: ordered_ids).update_all(famille: nil, sous_famille: nil, sous_sous_famille: nil, equivalence_key: nil)
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
