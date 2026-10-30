class RenameHgcTubeDurPebdRecycle < ActiveRecord::Migration[8.1]
  # HGC › Protection Câbles › Tubes de protection : la rubrique « Tube dur »
  # devient « Tube dur PEBD (basse densité) recyclé ». Idempotent, limité à HGC
  # (la rubrique « Tube dur » de Canplast ne change pas). Références inchangées.
  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    Product.where(supplier_id: hgc.id, famille: "Protection Câbles",
                  sous_famille: "Tubes de protection", sous_sous_famille: "Tube dur")
           .update_all(sous_sous_famille: "Tube dur PEBD (basse densité) recyclé", updated_at: Time.current)
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
