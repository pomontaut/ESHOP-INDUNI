class ExtendBoisC24PhotoToLambourdes < ActiveRecord::Migration[8.1]
  # "Lambourdes" (Leuba HIAG) are sawn dimensional softwood battens, visually
  # the same category as the "Bois C24" reference photo (stacked cut timber
  # beams) — extends that photo to them since no dedicated photo was
  # supplied. Poutrelles H20, Panneaux jaunes and Accessoires remain on the
  # icon tile: they look structurally different (I-beam, flat panel,
  # hardware) and no reference photo covers them yet.
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
