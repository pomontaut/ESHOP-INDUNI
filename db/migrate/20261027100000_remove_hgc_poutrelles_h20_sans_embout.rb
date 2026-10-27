class RemoveHgcPoutrellesH20SansEmbout < ActiveRecord::Migration[8.0]
  # Suppression des articles HG COMMERCIALE 127470, 127473, 127474 (Poutrelles H20 80x200 sans
  # embout). Les autres fournisseurs ne sont pas touchés. Si déjà commandé (clé étrangère
  # order_lines), il est conservé mais retiré du catalogue (sans famille).
  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    scope = Product.where(supplier_id: hgc.id, reference: %w[127470 127473 127474])
    ordered_ids = OrderLine.where(product_id: scope.select(:id)).distinct.pluck(:product_id)
    scope.where.not(id: ordered_ids).delete_all
    Product.where(id: ordered_ids).update_all(famille: nil, sous_famille: nil, sous_sous_famille: nil)
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
