class AddChantierAccessScopeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :chantier_access_scope, :string, default: "own", null: false
  end
end
