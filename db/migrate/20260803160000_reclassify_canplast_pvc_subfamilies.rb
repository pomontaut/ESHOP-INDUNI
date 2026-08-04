class ReclassifyCanplastPvcSubfamilies < ActiveRecord::Migration[8.1]
  # The "Canalisations PVC" famille (735 Canplast articles) was previously
  # sub-grouped by pipe SN-rating (SN2/SN4/SN8) for pipes, with every
  # fitting type crammed into a handful of oversized buckets ("Raccords"
  # alone mixed cement transition couplings with tapping-saddle hardware).
  # Reclassified into the categories the client actually shops by: pipe
  # sub-type (compact standard / drainage / CR0.5 à bétonner) plus one
  # bucket per fitting type (coudes, manchons, réductions, bouchons,
  # clapets, ouverture de nettoyage, raccord PVC ciment, embranchement/
  # manchettes), with anything that doesn't fit those (raccords de
  # piquage, raccords RCV/Flex, colle) in "Autres produits PVC".
  def up
    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    canplast = Supplier.find_by(name: "Canplast")
    return unless canplast

    items = JSON.parse(File.read(path)).select do |it|
      it["catalog"] == "Canplast" && it["famille"] == "Canalisations PVC"
    end

    items.each do |it|
      Product.where(supplier_id: canplast.id, reference: it["article"])
             .update_all(sous_famille: it["sousFamille"])
    end
  end

  def down
    # Data fix only — no rollback of the previous grouping.
  end
end
