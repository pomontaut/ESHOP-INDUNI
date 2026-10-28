class ReplaceHgcTuyauxPvcSn2Compact < ActiveRecord::Migration[8.0]
  # Les 4 tuyaux « PVC SN2 compact a.manchon a.joint » 100092505/506/535/536 (Ø150/200/250/300) sont
  # remplacés par les articles HGC 100063110-113 (+ 100022512 Ø350), désormais libellés « COMPACT »
  # (catalog_products.json). Si un ancien article est déjà commandé (clé étrangère order_lines), il est
  # conservé mais retiré du catalogue (sans famille ni équivalence).
  OLD_REFERENCES = %w[100092505 100092506 100092535 100092536].freeze

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
