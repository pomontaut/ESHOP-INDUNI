class CreateProductPriceChanges < ActiveRecord::Migration[8.0]
  # Historique des modifications de prix (date + nouveau prix), alimenté par
  # Product (callback) et par catalog:seed — uniquement quand le prix change
  # réellement (voir ProductPriceChange.record_seed_changes). Le prix actuel de
  # chaque article est repris comme prix initial, daté de sa création.
  def up
    create_table :product_price_changes do |t|
      t.references :product, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :price, null: false
      t.datetime :changed_at, null: false
      t.timestamps
    end
    add_index :product_price_changes, [ :product_id, :changed_at ]

    execute <<~SQL
      INSERT INTO product_price_changes (product_id, price, changed_at, created_at, updated_at)
      SELECT id, unit_price, COALESCE(created_at, CURRENT_TIMESTAMP), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM products
      WHERE unit_price IS NOT NULL
    SQL
  end

  def down
    drop_table :product_price_changes
  end
end
