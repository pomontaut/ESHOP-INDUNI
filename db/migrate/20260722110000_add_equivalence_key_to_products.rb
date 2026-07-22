class AddEquivalenceKeyToProducts < ActiveRecord::Migration[8.1]
  def up
    add_column :products, :equivalence_key, :string
    add_index :products, :equivalence_key

    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    supplier_ids = Supplier.where(name: [ "HGC", "Canplast", "Leuba HIAG" ]).pluck(:name, :id).to_h
    items = JSON.parse(File.read(path)).select { |it| it["equivalenceKey"].present? && supplier_ids.key?(it["catalog"]) }

    items.each do |it|
      Product.where(supplier_id: supplier_ids[it["catalog"]], reference: it["article"])
             .update_all(equivalence_key: it["equivalenceKey"])
    end
  end

  def down
    remove_index :products, :equivalence_key
    remove_column :products, :equivalence_key
  end
end
