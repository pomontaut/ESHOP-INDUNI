class ExtendPeCablePhotosToSimilarArticles < ActiveRecord::Migration[8.1]
  # Extends the 2 real "tuyau de protection câble PE" photos supplied by the
  # client to other straight-pipe articles (HGC and Canplast) whose
  # designation explicitly matches the same visual finish: "type K.."
  # (corrugated flexible conduit) or "manchonné ... avec lignes rouges" /
  # "manch.blanc" (smooth white pipe with a red stripe). Fittings/accessories
  # (coude, manchon, bouchon, raccord, joint, distanceur, bande, ficelle...)
  # and the green-striped variant are deliberately left untouched — they look
  # different from the supplied photos.
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
