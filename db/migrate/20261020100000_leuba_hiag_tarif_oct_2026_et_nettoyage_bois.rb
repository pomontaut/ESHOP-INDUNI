class LeubaHiagTarifOct2026EtNettoyageBois < ActiveRecord::Migration[8.0]
  # Comparatif bois Oct 2026 : le catalogue JSON (seed) porte les nouveaux prix
  # Leuba HIAG et les nouvelles références (piquets, coins, chabourys) ; cette
  # migration retire de la base :
  # - le « Plateau bois C24 50x300x4000 mm » (réf. 127483) chez Leuba HIAG et HG COMMERCIALE ;
  # - les panneaux filmés restants (contreplaqué bouleau film/film HG COMMERCIALE).
  # Un article déjà commandé ne peut pas être supprimé (clé étrangère order_lines) :
  # il est conservé mais retiré du catalogue (sans famille).
  def up
    suppliers = Supplier.where(name: [ "Leuba HIAG", "HG COMMERCIALE" ]).pluck(:id)
    hgc = Supplier.find_by(name: "HG COMMERCIALE")

    remove(Product.where(supplier_id: suppliers, reference: "127483"))
    remove(Product.where(supplier_id: hgc.id).where("name LIKE ?", "%film/film%")) if hgc
  end

  def down
    # Non réversible : no-op délibéré.
  end

  private

  def remove(scope)
    ordered_ids = OrderLine.where(product_id: scope.select(:id)).distinct.pluck(:product_id)
    scope.where.not(id: ordered_ids).delete_all
    Product.where(id: ordered_ids).update_all(famille: nil, sous_famille: nil, sous_sous_famille: nil)
  end
end
