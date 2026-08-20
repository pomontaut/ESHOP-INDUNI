class AddCantonToChantiers < ActiveRecord::Migration[8.1]
  def change
    add_column :chantiers, :canton, :string
  end
end
