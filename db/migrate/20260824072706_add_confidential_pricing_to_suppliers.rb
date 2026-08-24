class AddConfidentialPricingToSuppliers < ActiveRecord::Migration[8.1]
  def change
    add_column :suppliers, :confidential_pricing, :boolean, default: false, null: false
  end
end
