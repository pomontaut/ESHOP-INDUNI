class CreateChantierAssignments < ActiveRecord::Migration[8.0]
  # Affectation explicite d'un chantier à un utilisateur (Admin > Utilisateurs),
  # en plus de l'accès par e-mail technicien/contremaître/chef d'équipe et par
  # secteur (voir Chantier.visible_to).
  def change
    create_table :chantier_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :chantier, null: false, foreign_key: true
      t.timestamps
    end
    add_index :chantier_assignments, [ :user_id, :chantier_id ], unique: true
  end
end
