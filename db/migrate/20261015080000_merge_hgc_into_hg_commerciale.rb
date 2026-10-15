class MergeHgcIntoHgCommerciale < ActiveRecord::Migration[8.0]
  # « HGC » et « HG COMMERCIALE » sont le même fournisseur (même numéro
  # 230977) : une seule fiche, « HG COMMERCIALE », avec les articles les plus
  # récents par référence et sans doublon (voir SupplierMerger).
  def up
    SupplierMerger.merge!(target_name: "HG COMMERCIALE", source_names: [ "HGC" ])
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
