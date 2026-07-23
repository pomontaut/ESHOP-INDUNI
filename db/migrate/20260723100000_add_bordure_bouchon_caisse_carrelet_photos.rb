class AddBordureBouchonCaisseCarreletPhotos < ActiveRecord::Migration[8.1]
  # Third "Bibliothèque_photos.xlsx" batch: 4 new real reference photos
  # supplied by the client — bordure béton lisse, bouchon béton, caisse à
  # mortier en plastique, carrelet en bois. The other 12 photos in this
  # batch were already applied in previous migrations (identical images,
  # same file hashes). Matched narrowly to the exact article variant shown
  # in the photo: "bordure béton lisse" (not the "aspect granit" or "Etat
  # de Fribourg" bordures, which look different), "caisse à mortier en
  # plastique" only (not the round PVC or steel variants, which have a
  # different shape/material), and both HGC "carrelet sapin/épicéa brut"
  # references plus the cement-pipe-support carrelet (all plain wood
  # square beams) — the Leuba HIAG "carrelets/planches de coffrage" keep
  # their existing formwork-board photo since they're a different product.
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
