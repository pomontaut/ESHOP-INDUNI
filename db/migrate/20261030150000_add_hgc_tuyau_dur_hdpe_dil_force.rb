class AddHgcTuyauDurHdpeDilForce < ActiveRecord::Migration[8.1]
  # Nouvelle rubrique HGC « Protection Câbles › Tubes de protection › Tuyau dur HDPE
  # DIL-FORCE non recyclé » : tuyaux prot.câble HDPE a.manch. KRSEM-DIL Ø100 à Ø195 mm,
  # L10m avec manchon (4 articles hgc.ch). Aucune équivalence_key posée.
  REFERENCES = %w[100033273 100033275 100033277 100033279].freeze

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
