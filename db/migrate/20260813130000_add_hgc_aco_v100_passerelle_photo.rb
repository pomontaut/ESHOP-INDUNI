class AddHgcAcoV100PasserellePhoto < ActiveRecord::Migration[8.1]
  # Adds the photo for the ACO Multiline V100 grille passerelle A SK
  # acier zinguée L100cm — this is the image that was previously left
  # unmatched in an earlier Photo_HGC.xlsx batch (no visible "N°
  # article" label near it at the time); the client-supplied file now
  # carries the label ("N° article : 100019272" a few rows below the
  # image, same sheet), confirming the match.
  #
  # Only touches this 1 row directly by reference (see
  # AddHgcCaniveauAndCimentArticlePhotos for why a full-catalog loop is
  # too slow against Railway's networked Postgres).
  IMAGE_BY_REFERENCE = {
    "100019272" => "/images/products/hgc-aco-v100-grille-passerelle-l100.png"
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
