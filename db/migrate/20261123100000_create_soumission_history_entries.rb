# Mémoire « historique des soumissions BAT GE » de l'agent chiffreur (import soumission, test) :
# positions « fourniture et pose » lues dans 5'000 PDF 2010-2026, regroupées par texte + unité.
# Alimentée par le seed (db/seed_data/soumission_history.json.gz). Aucun prix, aucune clé étrangère.
class CreateSoumissionHistoryEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :soumission_history_entries do |t|
      t.text    :designation, null: false
      t.string  :norm_text, null: false
      t.text    :tokens, null: false, default: ""
      t.string  :code
      t.string  :unit
      t.string  :heading
      t.string  :scope, null: false, default: "article" # article | titre (expression dans le titre au-dessus)
      t.integer :occurrences, null: false, default: 1
      t.integer :affaires_count, null: false, default: 1
      t.integer :year_from
      t.integer :year_to
      t.string  :sample_affaire
      t.decimal :median_quantity, precision: 14, scale: 2
      t.timestamps
    end
    add_index :soumission_history_entries, [ :norm_text, :unit ], unique: true, name: "idx_soum_history_unique"
  end
end
