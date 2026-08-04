class ReclassifyPvcRaccordsAndSnSplits < ActiveRecord::Migration[8.1]
  # Canalisations PVC follow-up:
  # - Splits the 38 "Autres produits PVC" articles into a new "Raccords"
  #   sous-famille (Flex / piquetage / RCV, 32 articles) and keeps the
  #   6 remaining ones (clef de fixation / cloche / colle) under "Autres
  #   produits PVC" with their own sous-sous-famille.
  # - Refines "Coude standard", "Manchons coulissants/double", "Réductions"
  #   and "Embranchement culotte" into SN2/SN4 variants (the client wants
  #   these as an intermediate detail level, with angle as the next level
  #   for coudes/embranchements — computed client-side from the
  #   designation, not stored).
  # - Strips the "normalisé SIA 190 - EN 1401" norm reference from
  #   designations (redundant internal detail, not useful to buyers).
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
             .update_all(name: it["designation"], sous_famille: it["sousFamille"], sous_sous_famille: it["sousSousFamille"])
    end
  end

  def down
    # Data fix only — no rollback of the previous grouping.
  end
end
