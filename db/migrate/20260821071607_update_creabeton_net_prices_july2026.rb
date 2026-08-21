class UpdateCreabetonNetPricesJuly2026 < ActiveRecord::Migration[8.1]
  # Refreshes CreaBeton unit prices from MAJ_Juillet_2026_CREABETON_avec_prix_net.xlsx
  # ("Prix net CHF" column). Matched by article reference (ArtNr); only
  # references already present in our catalog are touched — references from
  # the xlsx that we don't carry are ignored, and references we carry that
  # aren't in the xlsx (or have no net price there) are left untouched.
  # Units of measure are never modified, only unit_price.
  def up
    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    creabeton = Supplier.find_by(name: "CreaBeton")
    return unless creabeton

    items = JSON.parse(File.read(path)).select { |it| it["catalog"] == "CreaBeton" }

    items.each do |it|
      Product.where(supplier_id: creabeton.id, reference: it["article"])
             .update_all(unit_price: it["prix"])
    end
  end

  def down
    # Data fix only — no rollback of the previous price list.
  end
end
