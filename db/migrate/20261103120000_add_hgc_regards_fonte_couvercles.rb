class AddHgcRegardsFonteCouvercles < ActiveRecord::Migration[8.1]
  # HGC « Fonte / Regard de voirie » : regards Fig.2640/2642 (inodore) et couvercles
  # fonte-béton D400 Fig.2716/2718, Normroll Fig.2750/2751 (hgc.ch, prix nets, photo HGC).
  # Upsert par référence (pas de doublon) : 5 regards existants sont mis à jour au prix net.
  FAMILLE = "Voirie & Aménagement".freeze
  ANCIENNE = "Voirie".freeze
  NOUVELLE = "Fonte / Regard de voirie".freeze
  REFERENCES = %w[
    100004969 100005011 100005013 100005015 100005017 100005019 100140468
    100005155 100005157 100005699 100005205 100005637 100005207
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
