class CreateProjetsAndSeanceLancements < ActiveRecord::Migration[8.1]
  def change
    create_table :projets do |t|
      t.string :nom, null: false
      t.string :numero
      t.references :chantier, foreign_key: { on_delete: :nullify }
      t.references :responsable, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :statut, null: false, default: "en_cours"
      t.text :description
      t.timestamps
    end

    create_table :seance_lancements do |t|
      t.references :projet, null: false, foreign_key: true, index: { unique: true }
      t.date :date_seance
      t.string :lieu
      t.text :participants
      t.decimal :budget_cible, precision: 12, scale: 2
      t.text :perimetre
      t.text :strategie_achat
      t.text :risques
      t.text :decisions
      t.text :actions
      t.boolean :realisee, null: false, default: false
      t.timestamps
    end
  end
end
