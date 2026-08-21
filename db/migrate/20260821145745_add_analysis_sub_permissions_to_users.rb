class AddAnalysisSubPermissionsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :can_view_market_indices, :boolean, default: false, null: false
    add_column :users, :can_view_intelligence_buying, :boolean, default: false, null: false
  end
end
