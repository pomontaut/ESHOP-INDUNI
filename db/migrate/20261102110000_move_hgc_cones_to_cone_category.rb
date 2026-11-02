class MoveHgcConesToConeCategory < ActiveRecord::Migration[8.1]
  # HGC « Préfa-béton » : les 8 cônes en béton symétriques passent de
  # « Autres produits préfa béton » à la nouvelle catégorie « Cône ».
  REFERENCES = %w[100018168 100018214 100018240 100018164 100018166 100018210 100078704 100018212].freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    Product.where(supplier_id: hgc.id, reference: REFERENCES, famille: "Préfa-béton")
           .update_all(sous_famille: "Cône", updated_at: Time.current)
  end

  def down
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    Product.where(supplier_id: hgc.id, reference: REFERENCES, famille: "Préfa-béton")
           .update_all(sous_famille: "Autres produits préfa béton", updated_at: Time.current)
  end
end
