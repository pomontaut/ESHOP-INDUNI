class AddCatalogPriceToOrderLines < ActiveRecord::Migration[8.1]
  def change
    add_column :order_lines, :catalog_price, :decimal
  end
end
