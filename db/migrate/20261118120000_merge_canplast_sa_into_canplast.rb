# « Canplast SA » (fiche créée par l'import de devis depuis la base fournisseurs comptable, sans e-mail) :
# l'envoi de la commande ESHOP_INDUNI_98 échouait (« Missing `to` field »). Rattache ses commandes et ses
# articles à la fiche « Canplast » (qui porte l'adresse de commande), puis supprime le doublon.
class MergeCanplastSaIntoCanplast < ActiveRecord::Migration[8.0]
  class MSupplier < ActiveRecord::Base; self.table_name = "suppliers"; end
  class MProduct < ActiveRecord::Base; self.table_name = "products"; end
  class MOrder < ActiveRecord::Base; self.table_name = "orders"; end
  class MOrderLine < ActiveRecord::Base; self.table_name = "order_lines"; end

  def up
    target = MSupplier.where("lower(name) = ?", "canplast").first
    dup    = MSupplier.where("lower(name) = ?", "canplast sa").first
    return unless target && dup && target.id != dup.id

    MOrder.where(supplier_id: dup.id).update_all(supplier_id: target.id)
    MProduct.where(supplier_id: dup.id).find_each do |product|
      same = MProduct.where(supplier_id: target.id, reference: product.reference).first
      if same
        MOrderLine.where(product_id: product.id).update_all(product_id: same.id)
        product.delete
      else
        product.update_columns(supplier_id: target.id)
      end
    end
    dup.delete
  end

  def down; end
end
