class CreateChantiers < ActiveRecord::Migration[8.1]
  def up
    create_table :chantiers do |t|
      t.string :nom, null: false
      t.text :contraintes_acces
      t.string :adresse
      t.string :npa
      t.string :ville
      t.string :carte_interactive
      t.string :technicien
      t.string :natel_technicien
      t.string :email_technicien
      t.string :contremaitre
      t.string :natel_contremaitre
      t.string :email_contremaitre
      t.string :chef_equipe
      t.string :natel_chef_equipe
      t.string :email_chef_equipe
      t.boolean :consortium, default: false, null: false
      t.timestamps
    end
    add_index :chantiers, :email_technicien
    add_index :chantiers, :email_contremaitre
    add_index :chantiers, :email_chef_equipe

    path = Rails.root.join("db/seed_data/chantiers.json")
    return unless File.exist?(path)

    now = Time.current
    rows = JSON.parse(File.read(path)).map do |it|
      it.slice(
        "nom", "contraintes_acces", "adresse", "npa", "ville", "carte_interactive",
        "technicien", "natel_technicien", "email_technicien",
        "contremaitre", "natel_contremaitre", "email_contremaitre",
        "chef_equipe", "natel_chef_equipe", "email_chef_equipe", "consortium"
      ).merge("created_at" => now, "updated_at" => now)
    end
    rows.each_slice(500) { |slice| Chantier.insert_all(slice) }
  end

  def down
    drop_table :chantiers
  end
end
