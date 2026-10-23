class CreateNomenclatureEntries < ActiveRecord::Migration[8.0]
  # Bibliothèque d'articles Induni (onglet « Nomenclature Induni », admin
  # seulement) : une ligne = un article Induni (n° de référence INDUNI) chez
  # un fournisseur. Alimentée par le seed (db/seed_data/nomenclature_induni.json).
  def change
    create_table :nomenclature_entries do |t|
      t.string :n_compta
      t.string :segmentation1
      t.string :segmentation2
      t.string :segmentation3
      t.string :induni_reference, null: false
      t.string :induni_designation
      t.string :supplier_name, null: false
      t.string :supplier_reference, null: false
      t.string :supplier_designation
      t.string :price_unit
      t.timestamps
    end
    add_index :nomenclature_entries, [ :induni_reference, :supplier_name ], unique: true
  end
end
