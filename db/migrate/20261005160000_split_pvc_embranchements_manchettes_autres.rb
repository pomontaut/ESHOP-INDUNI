class SplitPvcEmbranchementsManchettesAutres < ActiveRecord::Migration[8.1]
  # Canplast "Embranchement/manchettes" ne contient que des embranchements :
  # renommé "Embranchements". Les manchettes de raccordement PVC/ciment
  # (sorties de "Raccord PVC ciment") passent dans une catégorie "Manchettes".
  # HGC "Autres articles" (PVC) devient "Autres produits PVC".
  def up
    canplast = Supplier.find_by(name: "Canplast")
    if canplast
      Product.where(supplier_id: canplast.id, sous_famille: "Embranchement/manchettes")
             .update_all(sous_famille: "Embranchements")
      Product.where(supplier_id: canplast.id, famille: "Canalisations PVC",
                    sous_famille: "Raccord PVC ciment",
                    sous_sous_famille: "Manchette de raccordement PVC/ciment")
             .update_all(sous_famille: "Manchettes")
    end

    hgc = Supplier.find_by(name: "HGC")
    if hgc
      Product.where(supplier_id: hgc.id, famille: "Canalisations PVC", sous_famille: "Autres articles")
             .update_all(sous_famille: "Autres produits PVC")
    end
  end

  def down
    # Data fix only.
  end
end
