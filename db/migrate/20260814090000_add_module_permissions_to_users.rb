class AddModulePermissionsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :can_import_quote, :boolean, default: false, null: false
    add_column :users, :can_generic_order, :boolean, default: false, null: false
  end
end
