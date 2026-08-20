class AddFeaturePermissionsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :can_view_dashboard, :boolean, default: false, null: false
    add_column :users, :can_view_analysis, :boolean, default: false, null: false
    add_column :users, :can_view_nomenclature, :boolean, default: false, null: false
  end
end
