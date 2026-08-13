class AddHgcMortierRapidePhotos < ActiveRecord::Migration[8.1]
  # Adds real photo paths (public/images/products/...) for 8 more HGC
  # articles that had no photo yet, extracted from an updated
  # Photo_HGC.xlsx — quick-set mortars/admixtures (weber ip14/ip18,
  # GrasCalce béton rapide, Biber-Rapid, PCI Polyfix Plus, Sika-4A
  # 5kg/15kg, Vicat ciment prompt) — position-based matching against
  # "N° article" labels.
  #
  # Only touches these 8 rows directly by reference (see
  # AddHgcCaniveauAndCimentArticlePhotos for why a full-catalog loop is
  # too slow against Railway's networked Postgres).
  IMAGE_BY_REFERENCE = {
    "100096695" => "/images/products/hgc-weber-ip14.png",
    "100096662" => "/images/products/hgc-weber-ip18.png",
    "100003573" => "/images/products/hgc-grascalce-beton-rapide.png",
    "100016103" => "/images/products/hgc-mortier-biber-rapid.png",
    "100015962" => "/images/products/hgc-pci-polyfix-plus.png",
    "100009449" => "/images/products/hgc-sika-4a-15kg.png",
    "100009447" => "/images/products/hgc-sika-4a-5kg.png",
    "100000142" => "/images/products/hgc-vicat-ciment-prompt.png"
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
