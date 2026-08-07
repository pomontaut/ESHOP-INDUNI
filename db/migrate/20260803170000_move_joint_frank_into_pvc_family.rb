class MoveJointFrankIntoPvcFamily < ActiveRecord::Migration[8.1]
  # The 23 "Joint système Frank©" articles (JTF0025..JTF1200) were filed
  # under "Fournitures & Divers" — their diameters exactly match the PVC
  # pipe range, and the client wants them visible under the PVC family as
  # their own "Joint Frank" sub-family instead.
  def up
    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    canplast = Supplier.find_by(name: "Canplast")
    return unless canplast

    items = JSON.parse(File.read(path)).select { |it| it["catalog"] == "Canplast" && it["article"].start_with?("JTF") }

    items.each do |it|
      Product.where(supplier_id: canplast.id, reference: it["article"])
             .update_all(famille: it["famille"], sous_famille: it["sousFamille"])
    end
  end

  def down
    # Data fix only — no rollback of the previous grouping.
  end
end
