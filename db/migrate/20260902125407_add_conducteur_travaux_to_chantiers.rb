class AddConducteurTravauxToChantiers < ActiveRecord::Migration[8.1]
  def change
    add_column :chantiers, :conducteur_travaux, :string
    add_column :chantiers, :natel_conducteur_travaux, :string
    add_column :chantiers, :email_conducteur_travaux, :string
    add_index :chantiers, :email_conducteur_travaux
  end
end
