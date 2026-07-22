class SyncRealProductPhotos < ActiveRecord::Migration[8.1]
  # Syncs the `image` column from catalog_products.json again. Unlike the
  # generic Unsplash-keyword refresh, this batch replaces a handful of
  # entries with a real photo path (public/images/products/...) supplied
  # by the client for the exact matching article designation.
  def up
    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    supplier_ids = Supplier.where(name: [ "HGC", "Canplast", "Leuba HIAG" ]).pluck(:name, :id).to_h
    return if supplier_ids.empty?

    items = JSON.parse(File.read(path)).select { |it| supplier_ids.key?(it["catalog"]) }

    items.each do |it|
      Product.where(supplier_id: supplier_ids[it["catalog"]], reference: it["article"])
             .update_all(image: it["image"])
    end
  end

  def down
    # Data fix only — no rollback.
  end
end
