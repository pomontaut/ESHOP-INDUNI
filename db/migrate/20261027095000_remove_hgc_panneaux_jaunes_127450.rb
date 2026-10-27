class RemoveHgcPanneauxJaunes127450 < ActiveRecord::Migration[8.0]
  # Suppression de l'article HG COMMERCIALE 127450 (Panneaux jaunes 27x2500x500 mm). Le même
  # numéro chez Leuba HIAG est conservé. Si déjà commandé (clé étrangère
  # order_lines), il est conservé mais retiré du catalogue (sans famille).
  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    scope = Product.where(supplier_id: hgc.id, reference: "127450")
    ordered_ids = OrderLine.where(product_id: scope.select(:id)).distinct.pluck(:product_id)
    scope.where.not(id: ordered_ids).delete_all
    Product.where(id: ordered_ids).update_all(famille: nil, sous_famille: nil, sous_sous_famille: nil)
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
