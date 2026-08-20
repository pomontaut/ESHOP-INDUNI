class AddReceptionConfirmationToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :reception_token, :string
    add_index :orders, :reception_token, unique: true
    add_column :orders, :reception_confirmed_at, :datetime
  end
end
