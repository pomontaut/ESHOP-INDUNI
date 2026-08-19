class AddModifiesOrderToOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :modifies_order, foreign_key: { to_table: :orders, on_delete: :nullify }, index: true
  end
end
