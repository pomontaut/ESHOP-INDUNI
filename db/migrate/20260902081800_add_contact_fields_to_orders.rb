class AddContactFieldsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :contact, :string
    add_column :orders, :phone, :string
    add_column :orders, :delivery_address, :text
    add_column :orders, :conducteur_travaux, :string
  end
end
