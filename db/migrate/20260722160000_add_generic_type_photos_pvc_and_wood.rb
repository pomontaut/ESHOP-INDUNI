class AddGenericTypePhotosPvcAndWood < ActiveRecord::Migration[8.1]
  # Second "Bibliothèque_photos.xlsx" batch: 9 new generic (non-SKU-specific)
  # reference photos, matched broadly to every article whose designation
  # confirms the same product type — tuyau PVC, coude PVC 45°, embranchement/
  # culotte PVC 90°, tuyau PVC perforé, réduction PVC, planche de coffrage,
  # bois C24, panneaux filmés, panneau OSB3 — plus a broader re-application
  # of the existing "tuyau protection câble" photo to straight PE-câbles
  # pipe variants left unmatched in the previous batch (rolls, "fermeture
  # longitudinale", unspecified finish) now that the client supplied a
  # generic label for the whole family. Fittings and angle variants without
  # a supplied photo (15°/30°/67°/90° coudes, 45° embranchements, coude
  # plongeur/long, etc.) are deliberately left on the icon tile.
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
