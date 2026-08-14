class AddPrixM2ToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :prix_m2, :decimal
  end
end
