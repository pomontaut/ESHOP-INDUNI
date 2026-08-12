class AddHgcCaniveauAndCimentArticlePhotos < ActiveRecord::Migration[8.1]
  # Syncs the `image` column from catalog_products.json again. Adds real
  # photo paths (public/images/products/...) for 9 HGC articles that had
  # no photo yet — 2 "Autres produits" caniveau articles (bride, caniveau
  # de câbles no.4) and 7 CEM II cement articles (Holcim, Vigier, Optimo 4,
  # Ciment Fondu, gravier BigBag, Kerakoll Keracem, Kerabuild Osmocem) —
  # extracted from the client-supplied Photo_HGC.xlsx (position-based
  # matching to designation labels, same rule as prior photo batches).
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
