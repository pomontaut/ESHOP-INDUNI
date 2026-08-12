class AddHgcCaniveauAndCimentArticlePhotos < ActiveRecord::Migration[8.1]
  # Adds real photo paths (public/images/products/...) for 9 HGC articles
  # that had no photo yet — 2 "Autres produits" caniveau articles (bride,
  # caniveau de câbles no.4) and 7 CEM II cement articles (Holcim, Vigier,
  # Optimo 4, Ciment Fondu, gravier BigBag, Kerakoll Keracem, Kerabuild
  # Osmocem) — extracted from the client-supplied Photo_HGC.xlsx
  # (position-based matching to designation labels, same rule as prior
  # photo batches).
  #
  # Only touches these 9 rows (unlike the earlier SyncRealProductPhotos
  # migration, which looped every HGC/Canplast/Leuba HIAG row with a
  # separate UPDATE query each — fine on localhost, but ~2600 sequential
  # round trips to a networked Postgres instance blew past Railway's
  # 5-minute healthcheck window on boot).
  IMAGE_BY_REFERENCE = {
    "100054348" => "/images/products/hgc-caniveau-bride.png",
    "100054343" => "/images/products/hgc-caniveau-cable-no4.png",
    "100097537" => "/images/products/hgc-ciment-holcim-blanc.png",
    "100000204" => "/images/products/hgc-ciment-vigier-cem2.png",
    "100000044" => "/images/products/hgc-ciment-optimo4.png",
    "100058613" => "/images/products/hgc-ciment-fondu.png",
    "100001051" => "/images/products/hgc-gravier-bigbag.png",
    "100084516" => "/images/products/hgc-ciment-kerakoll-keracem.png",
    "100022812" => "/images/products/hgc-ciment-kerabuild-osmocem.png"
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
