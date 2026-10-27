class RemoveHgcPfeifer100007004500000316 < ActiveRecord::Migration[8.0]
  # Suppression des articles HG COMMERCIALE 100007004 (ancien n° du Pfeifer 27mm
  # 50x200cm, remplacé par 100007096) et 500000316 (doublon Pfeifer 27mm 50x250cm).
  # Déjà commandé (clé étrangère order_lines) : conservé mais retiré du catalogue.
  REFERENCES = %w[100007004 500000316].freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    scope = Product.where(supplier_id: hgc.id, reference: REFERENCES)
    ordered_ids = OrderLine.where(product_id: scope.select(:id)).distinct.pluck(:product_id)
    scope.where.not(id: ordered_ids).delete_all
    Product.where(id: ordered_ids).update_all(famille: nil, sous_famille: nil, sous_sous_famille: nil)
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
