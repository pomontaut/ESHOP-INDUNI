class RemoveHgcEmbranchementsKgea3References < ActiveRecord::Migration[8.0]
  # Embranchements PVC dur 45° KGEA retirés du catalogue HGC à la demande du propriétaire
  # (Ø150/125, Ø150/150, Ø200/150 : les derniers). Une référence déjà commandée (clé étrangère
  # order_lines) est conservée mais sortie du catalogue (sans famille ni équivalence).
  OLD_REFERENCES = %w[100098809 100098810 100098813].freeze

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
