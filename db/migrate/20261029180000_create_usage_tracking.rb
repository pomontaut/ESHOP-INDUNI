class CreateUsageTracking < ActiveRecord::Migration[8.0]
  # Agent d'usage de l'e-shop (administrateur seulement) : une « session d'usage » = une
  # ouverture de l'e-shop dans un onglet (jeton conservé tant que l'onglet reste actif), des
  # événements (login, visit, click, nav, search, add_to_cart) et l'archive des comptes rendus
  # quotidiens. Aucune clé étrangère SQL : la purge des commandes ou des utilisateurs n'y touche pas.
  def change
    create_table :usage_sessions do |t|
      t.string   :token, null: false
      t.integer  :user_id, null: false
      t.datetime :started_at, null: false
      t.datetime :last_seen_at, null: false
      t.integer  :active_seconds, null: false, default: 0
      t.integer  :clicks, null: false, default: 0
      t.string   :user_agent
      t.timestamps
    end
    add_index :usage_sessions, :token, unique: true
    add_index :usage_sessions, [ :user_id, :started_at ]

    create_table :usage_events do |t|
      t.integer  :usage_session_id
      t.integer  :user_id, null: false
      t.string   :kind, null: false
      t.text     :data
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :usage_events, [ :occurred_at, :user_id ]
    add_index :usage_events, :usage_session_id

    create_table :usage_reports do |t|
      t.date     :report_date, null: false
      t.text     :summary
      t.datetime :emailed_at
      t.timestamps
    end
    add_index :usage_reports, :report_date, unique: true
  end
end
