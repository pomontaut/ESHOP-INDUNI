class AddHgcCoudeFlexibleCourt < ActiveRecord::Migration[8.1]
  # Nouvelle rubrique HGC « Protection Câbles › Coudes › Coude flexible court » :
  # coudes PE 90° / 45° câble lisse KRB (Ø60 à Ø200 mm), 12 articles hgc.ch.
  # Aucune équivalence_key : pas d'équivalent Canplast à diamètre exact vérifié.
  REFERENCES = %w[
    100034252 100034254 100034256 100034258 100034290 100034292
    100034294 100034296 100034298 100034330 100034332 100034334
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
