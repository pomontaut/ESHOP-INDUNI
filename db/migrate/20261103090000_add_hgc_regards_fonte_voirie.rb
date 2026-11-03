class AddHgcRegardsFonteVoirie < ActiveRecord::Migration[8.1]
  # HGC « Voirie & Aménagement » : la sous-rubrique « Voirie » devient
  # « Fonte / Regard de voirie » et reçoit les regards en fonte A15 Fig.2612 /
  # B125 Fig.2613 (hgc.ch, prix nets). Idempotent : upsert par référence, donc
  # pas de doublon ; les deux regards déjà présents (100004805, 100004913) sont
  # mis à jour (désignation, prix net, photo).
  FAMILLE = "Voirie & Aménagement".freeze
  ANCIENNE = "Voirie".freeze
  NOUVELLE = "Fonte / Regard de voirie".freeze
  REFERENCES = %w[
    100004805 100004857 100004913 100004853 100004855 100004859 100004911
    100004915 100004917 100004919 100005387 100070331 100140390
  ].freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    Product.where(supplier_id: hgc.id, famille: FAMILLE, sous_famille: ANCIENNE)
           .update_all(sous_famille: NOUVELLE, updated_at: Time.current)

    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    items = JSON.parse(File.read(path)).select do |it|
      it["catalog"] == "HG COMMERCIALE" && REFERENCES.include?(it["article"])
    end
    now = Time.current
    rows = items.map do |it|
      {
        supplier_id: hgc.id, reference: it["article"], name: it["designation"],
        unit_price: it["prix"], descriptif: it["descriptif"], unite: it["unite"],
        famille: it["famille"], sous_famille: it["sousFamille"],
        sous_sous_famille: it["sousSousFamille"], icone: it["icone"],
        poids_kg: it["poids"], image: it["image"], created_at: now, updated_at: now
      }
    end
    Product.upsert_all(rows, unique_by: :index_products_on_supplier_id_and_reference) if rows.any?
  end

  def down
    # Data refresh only — no rollback of catalog contents.
  end
end
