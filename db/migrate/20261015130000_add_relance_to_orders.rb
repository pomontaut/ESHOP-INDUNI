class AddRelanceToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :relance_sent_at, :datetime
    add_column :orders, :relance_kind, :string # "auto" ou "manuel"
  end
end
