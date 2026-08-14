class AddNeedsClassificationToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :needs_classification, :boolean, default: false, null: false
  end
end
