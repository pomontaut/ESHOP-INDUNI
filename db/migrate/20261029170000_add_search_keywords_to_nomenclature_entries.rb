class AddSearchKeywordsToNomenclatureEntries < ActiveRecord::Migration[8.0]
  # Nomenclature Induni renumérotée (classement ABACUS) : la bibliothèque est entièrement recalculée
  # depuis db/seed_data/nomenclature_induni.json (aucune clé étrangère vers cette table). Ajoute les
  # mots clefs d'aide à la recherche et une clé unique par ligne fournisseur (plusieurs références
  # d'un même fournisseur peuvent partager un n° INDUNI).
  def up
    add_column :nomenclature_entries, :search_keywords, :text
    remove_index :nomenclature_entries, column: [ :induni_reference, :supplier_name ]
    add_index :nomenclature_entries, [ :induni_reference, :supplier_name, :supplier_reference ], unique: true,
              name: "index_nomenclature_entries_on_induni_and_supplier"
    NomenclatureEntry.reset_column_information
    NomenclatureEntry.seed_from_json!
  end

  def down
    remove_index :nomenclature_entries, name: "index_nomenclature_entries_on_induni_and_supplier"
    add_index :nomenclature_entries, [ :induni_reference, :supplier_name ], unique: true
    remove_column :nomenclature_entries, :search_keywords
  end
end
