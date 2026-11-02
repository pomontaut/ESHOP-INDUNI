class AddHgcTuyauxBetonRond2 < ActiveRecord::Migration[8.1]
  # HGC « Préfa-béton › Tuyaux & bordures béton › Tuyaux béton rond » : 50 tuyaux en béton non armé
  # courts Ø100–500 mm, L50–500 mm (hgc.ch, prix nets).
  REFERENCES = %w[
    100015125 100015127 100015129 100015161 100015163 100015165 100015210 100015212 100015214
    100015216 100015218 100015260 100015262 100015264 100015266 100015268 100015300 100015302
    100015304 100015306 100015308 100015351 100015353 100015355 100015357 100015359 100015381
    100015387 100015389 100015431 100015433 100015435 100015437 100015439 100015483 100015485
    100015487 100015489 100015511 100015514 100015516 100015556 100015558 100015590 100015592
    100015596 100015598 100015643 100015647 100015649
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
