class ReclassifyCanplastPvcLevel3 < ActiveRecord::Migration[8.1]
  # Adds the "menu 3" breakdown (sous_sous_famille) inside 9 of the PVC
  # sous-familles, per the client's explicit sub-categories, and moves 6
  # articles that were sitting in "Clapets" (their designation is actually
  # "Ouverture de nettoyage ... avec clapet antirefoulement") into
  # "Ouverture de nettoyage" where they belong.
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
             .update_all(sous_famille: it["sousFamille"], sous_sous_famille: it["sousSousFamille"])
    end
  end

  def down
    # Data fix only — no rollback of the previous grouping.
  end
end
