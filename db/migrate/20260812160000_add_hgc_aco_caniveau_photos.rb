class AddHgcAcoCaniveauPhotos < ActiveRecord::Migration[8.1]
  # Adds real photo paths (public/images/products/...) for 5 more HGC
  # articles that had no photo yet, extracted from an updated
  # Photo_HGC.xlsx — ACO Multiline caniveau grilles and steel-edged
  # channel bodies (position-based matching against "N° article"
  # labels).
  #
  # Only touches these 5 rows directly by reference (see the
  # AddHgcCaniveauAndCimentArticlePhotos migration for why a
  # full-catalog loop is too slow against Railway's networked
  # Postgres).
  IMAGE_BY_REFERENCE = {
    "100022532" => "/images/products/hgc-caniveau-grille-fonte-ggg-c.png",
    "100081659" => "/images/products/hgc-caniveau-grille-fonte-v200.png",
    "100018834" => "/images/products/hgc-caniveau-cadre-acier-v100-l100.png",
    "100018870" => "/images/products/hgc-caniveau-cadre-acier-v100-l50.png",
    "100020661" => "/images/products/hgc-caniveau-cadre-acier-v200-l100.png"
  }.freeze

  def up
    supplier = Supplier.find_by(name: "HGC")
    return unless supplier

    IMAGE_BY_REFERENCE.each do |reference, image|
      Product.where(supplier_id: supplier.id, reference: reference).update_all(image: image)
    end
  end

  def down
    # Data fix only — no rollback.
  end
end
