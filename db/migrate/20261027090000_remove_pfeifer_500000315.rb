class RemovePfeifer500000315 < ActiveRecord::Migration[8.0]
  # Suppression de l'article HG COMMERCIALE 500000315 (Pfeifer panneau de coffrage
  # 27mm 50x200cm, doublon de 100007004). S'il a déjà été commandé (clé étrangère
  # order_lines), il est conservé mais retiré du catalogue (sans famille).
  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    scope = Product.where(supplier_id: hgc.id, reference: "500000315")
    ordered_ids = OrderLine.where(product_id: scope.select(:id)).distinct.pluck(:product_id)
    scope.where.not(id: ordered_ids).delete_all
    Product.where(id: ordered_ids).update_all(famille: nil, sous_famille: nil, sous_sous_famille: nil)
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
