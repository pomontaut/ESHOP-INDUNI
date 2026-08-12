class AddHgcMortarToolsAndPciPhotos < ActiveRecord::Migration[8.1]
  # Adds real photo paths (public/images/products/...) for 9 more HGC
  # articles that had no photo yet, extracted from an updated
  # Photo_HGC.xlsx (same position-based matching rule as prior batches,
  # this time with explicit "N° article" labels): mortar tubs (plastique
  # 200L, acier 50L, PVC 65L/90L), carrelet en bois, seau à mortier,
  # taquets ciment (25mm/30mm), and PCI Repaflow.
  #
  # Only touches these 9 rows directly by reference (see the
  # AddHgcCaniveauAndCimentArticlePhotos migration for why a full-catalog
  # loop is too slow against Railway's networked Postgres).
  IMAGE_BY_REFERENCE = {
    "100000979" => "/images/products/hgc-caisse-mortier-plastique-200l.png",
    "100001545" => "/images/products/hgc-caisse-mortier-acier-50l.png",
    "100001498" => "/images/products/hgc-caisse-mortier-pvc-65l.png",
    "100001541" => "/images/products/hgc-caisse-mortier-pvc-90l.png",
    "500000001" => "/images/products/hgc-carrelet-bois.png",
    "100001442" => "/images/products/hgc-seau-mortier-plastique.png",
    "100011576" => "/images/products/hgc-taquet-ciment-25mm.png",
    "100011620" => "/images/products/hgc-taquet-ciment-30mm.png",
    "100009826" => "/images/products/hgc-pci-repaflow.png"
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
