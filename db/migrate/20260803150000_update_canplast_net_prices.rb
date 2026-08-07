class UpdateCanplastNetPrices < ActiveRecord::Migration[8.1]
  # Refreshes Canplast unit prices from Catalogue_canplast_maj_15062026.xlsx
  # ("Montant net" column — the negotiated net price, excluding RPLP which
  # this sheet explicitly flags as "RPLP ? Non" and is charged separately
  # in the eshop). Matched by article reference; the two Canplast codes
  # that are non-unique in their own catalog (PIQUAGECLEF, PIQUAGECLOCHE)
  # are already disambiguated as -160/-200 in our data, same as the
  # original catalog import.
  def up
    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    canplast = Supplier.find_by(name: "Canplast")
    return unless canplast

    items = JSON.parse(File.read(path)).select { |it| it["catalog"] == "Canplast" }

    items.each do |it|
      Product.where(supplier_id: canplast.id, reference: it["article"])
             .update_all(unit_price: it["prix"])
    end
  end

  def down
    # Data fix only — no rollback of the previous price list.
  end
end
