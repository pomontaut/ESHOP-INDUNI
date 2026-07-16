class AddPermissionsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :can_create_users,  :boolean, default: false, null: false
    add_column :users, :can_create_orders, :boolean, default: false, null: false
    add_column :users, :can_modify_orders, :boolean, default: false, null: false
    add_column :users, :can_read,          :boolean, default: true,  null: false
    add_column :users, :allowed_suppliers, :string, array: true, default: []
    add_column :users, :order_limit,       :decimal, precision: 10, scale: 2
    add_column :users, :approver_email,    :string
  end
end
