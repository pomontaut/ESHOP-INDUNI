class RemoveBoisArticlesFilmesCarreletsAccessoires < ActiveRecord::Migration[8.0]
  # Nettoyage de la liste bois (Leuba HIAG et HG COMMERCIALE) :
  # - panneaux filmés (sous-famille « Panneaux filmés ») supprimés ;
  # - carrelets / planches 50x300x4000 supprimés chez les deux fournisseurs
  #   (chez HG COMMERCIALE : aussi le plateau d'échafaudage 50x300 L4000) ;
  # - chez Leuba HIAG : Bois C24 24/27x150x4000 et tout article « Douglas » ;
  # - sous-famille « Accessoires » : ne reste que les panneaux de protection.
  # Un article déjà commandé ne peut pas être supprimé (clé étrangère
  # order_lines) : il est conservé mais retiré du catalogue (sans famille).
  FAMILLE = "Bois & Coffrage".freeze
  PROTECTION_PANELS = %w[104662 104629].freeze

  def up
    leuba = Supplier.find_by(name: "Leuba HIAG")
    hgc   = Supplier.find_by(name: "HG COMMERCIALE")
    both  = [ leuba, hgc ].compact.map(&:id)

    remove(Product.where(supplier_id: both, sous_famille: "Panneaux filmés"))
    remove(Product.where(supplier_id: both).where("name LIKE ?", "%Carrelets / planches de coffrage 50x300x4000%"))
    if hgc
      remove(Product.where(supplier_id: hgc.id).where("name LIKE ? AND name LIKE ?", "Plateau d'échafaudage%", "%50x300mm L4000mm%"))
    end
    if leuba
      remove(Product.where(supplier_id: leuba.id).where("lower(name) LIKE ?", "%douglas%"))
      remove(Product.where(supplier_id: leuba.id).where("name LIKE ? AND (name LIKE ? OR name LIKE ?)", "%C24%", "%24x150x4000%", "%27x150x4000%"))
    end
    remove(
      Product.where(supplier_id: both, famille: FAMILLE, sous_famille: "Accessoires")
             .where.not(reference: PROTECTION_PANELS)
             .where.not("lower(name) LIKE ?", "%protection%")
    )
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
