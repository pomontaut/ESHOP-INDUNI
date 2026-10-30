class AddHgcTuyauDurLdpeCoextrudeSn4 < ActiveRecord::Migration[8.1]
  # Nouvelle rubrique HGC « Protection Câbles › Tubes de protection › Tuyau dur LDPE
  # co-extrudé recyclé (SN4) » : tuyaux de protec.câble LDPE a.manch. KRSEM Ø60 à Ø200 mm,
  # L5m et L10m (12 articles hgc.ch). 100033022 existait déjà (rubrique directe, 4.37) :
  # il est déplacé et son prix mis à jour (upsert). Aucune équivalence_key.
  REFERENCES = %w[
    100033022 100033024 100033026 100033028 100033060 100033062
    100033064 100033066 100033068 100033110 100033111 100033113
  ].freeze

  def up
    hgc = Supplier.find_by(name: "HGC")
    return unless hgc

    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    items = JSON.parse(File.read(path)).select do |it|
      it["catalog"] == "HG COMMERCIALE" && REFERENCES.include?(it["article"])
    end
    now = Time.current

    rows = items.map do |it|
      {
        supplier_id:       hgc.id,
        reference:         it["article"],
        name:              it["designation"],
        unit_price:        it["prix"],
        descriptif:        it["descriptif"],
        unite:             it["unite"],
        famille:           it["famille"],
        sous_famille:      it["sousFamille"],
        sous_sous_famille: it["sousSousFamille"],
        icone:             it["icone"],
        poids_kg:          it["poids"],
        image:             it["image"],
        created_at:        now,
        updated_at:        now
      }
    end

    Product.upsert_all(rows, unique_by: :index_products_on_supplier_id_and_reference) if rows.any?
  end

  def down
    # Data refresh only — no rollback of catalog contents.
  end
end
