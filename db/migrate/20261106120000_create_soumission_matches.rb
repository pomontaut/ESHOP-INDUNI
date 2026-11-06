# Mémoire du module « Import soumission » (environnement Développement) : rapprochement validé
# (ou refusé) entre une désignation de soumission et un article du catalogue. Réutilisé aux
# soumissions suivantes : c'est l'« expérience » de l'agent chiffreur.
class CreateSoumissionMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :soumission_matches do |t|
      t.string  :norm_designation, null: false
      t.string  :designation
      t.string  :supplier_name, null: false
      t.string  :product_reference, null: false
      t.string  :status, null: false, default: "confirmed" # confirmed | rejected
      t.integer :uses, null: false, default: 1
      t.integer :user_id
      t.timestamps
    end
    add_index :soumission_matches, [ :norm_designation, :supplier_name, :product_reference ], unique: true, name: "idx_soumission_matches_unique"
    add_index :soumission_matches, :norm_designation
  end
end
