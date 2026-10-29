class CreateSearchAgent < ActiveRecord::Migration[8.0]
  # Agent « moteur de recherche » (chat administrateur) : mémoire de recherche (synonymes et mots clefs
  # supplémentaires par article, appris en direct ou proposés d'après l'agent d'usage) et historique du chat.
  # Aucune clé étrangère SQL.
  def change
    create_table :search_memories do |t|
      t.string  :kind, null: false                 # synonym | keyword
      t.string  :status, null: false, default: "active" # active | suggested | ignored
      t.string  :term                              # synonym : mot tapé par l'utilisateur
      t.text    :value, null: false                # synonym : équivalents ; keyword : mots clefs ajoutés
      t.boolean :one_way, null: false, default: false
      t.string  :induni_reference                  # keyword : cible = article INDUNI (toutes ses lignes fournisseur)…
      t.string  :supplier_name                     # … ou une référence fournisseur précise
      t.string  :supplier_reference
      t.string  :target_label
      t.string  :source, null: false, default: "chat" # chat | suggestion
      t.string  :note
      t.integer :created_by_id
      t.timestamps
    end
    add_index :search_memories, [ :kind, :status ]

    create_table :search_agent_messages do |t|
      t.integer :user_id, null: false
      t.string  :role, null: false # user | agent
      t.text    :content, null: false
      t.timestamps
    end
    add_index :search_agent_messages, :created_at
  end
end
