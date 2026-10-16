class CreateChantierContacts < ActiveRecord::Migration[8.0]
  # Personnes supplémentaires d'un chantier (gros chantiers) : plusieurs
  # techniciens, contremaîtres, chefs d'équipe ou contacts de réception de
  # livraison. La personne « principale » reste dans les colonnes de chantiers.
  def change
    create_table :chantier_contacts do |t|
      t.references :chantier, null: false, foreign_key: true
      t.string :role, null: false
      t.string :nom
      t.string :natel
      t.string :email
      t.timestamps
    end
    add_index :chantier_contacts, :email
    add_index :chantier_contacts, [ :chantier_id, :role ]
  end
end
