class AddHgcTuyauDurHdpeCoextrudeSn8 < ActiveRecord::Migration[8.1]
  # Nouvelle rubrique HGC « Protection Câbles › Tubes de protection › Tuyau dur HDPE
  # co-extrudé recyclé (SN8) » : tuyaux de protec.câble HDPE a.manch. KRSEM Ø60 à Ø291 mm,
  # L5m et L10m (16 articles hgc.ch). Aucune équivalence_key (diamètre exact non vérifié).
  REFERENCES = %w[
    100080336 100080337 100080338 100080339 100080490 100080491 100080492 100080493
    100080494 100080495 100107513 100135671 100135672 100135673 100135674 100135675
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
