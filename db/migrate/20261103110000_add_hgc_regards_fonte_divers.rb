class AddHgcRegardsFonteDivers < ActiveRecord::Migration[8.1]
  # HGC « Fonte / Regard de voirie » : regards Fig.2660/2661 (inodore, A15/B125), 2583,
  # Normroll D400 Fig.2650 et Fig.2730 (hgc.ch, prix nets, photo HGC). Upsert par référence
  # (pas de doublon) : 100004807 et 100005049 sont mis à jour.
  FAMILLE = "Voirie & Aménagement".freeze
  ANCIENNE = "Voirie".freeze
  NOUVELLE = "Fonte / Regard de voirie".freeze
  REFERENCES = %w[
    100005047 100005091 100005097 100005349 100005043 100005049 100005093
    100005095 100005343 100005345 100005347 100005381 100005443 100005491
    100004753 100004807 100082825 100004803 100004809 100082923 100083956
    100004965
  ].freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

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
