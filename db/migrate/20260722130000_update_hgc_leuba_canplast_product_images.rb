class UpdateHgcLeubaCanplastProductImages < ActiveRecord::Migration[8.1]
  # Refreshes the `image` keyword used to build the storefront's Unsplash
  # search URL — previously one blanket keyword per famille (27 distinct
  # values across 2637 products), now derived per-article from the parsed
  # designation/descriptif (product type + material), so photos are more
  # likely to resemble the actual article.
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
    # Data fix only — no rollback of the previous (coarser) keywords.
  end
end
