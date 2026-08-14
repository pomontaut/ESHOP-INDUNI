class AddPoidsKgToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :poids_kg, :decimal
  end
end
