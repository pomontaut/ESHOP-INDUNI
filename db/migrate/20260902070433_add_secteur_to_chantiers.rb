class AddSecteurToChantiers < ActiveRecord::Migration[8.1]
  def change
    add_column :chantiers, :secteur, :string
  end
end
