class AddHgcTuyauxBetonRond3 < ActiveRecord::Migration[8.1]
  # HGC « Préfa-béton › Tuyaux & bordures béton › Tuyaux béton rond » : 44 tuyaux en béton non armé
  # (Ø200–3000 mm, L50–900 mm, hgc.ch, prix nets).
  REFERENCES = %w[
    100015693 100015695 100015699 100015749 100015771 100015773 100015778 100015820 100015822
    100015824 100015826 100015828 100015861 100015863 100015913 100015915 100015917 100015963
    100015968 100016000 100016002 100016004 100016006 100016050 100016052 100016054 100078435
    100078444 100083745 100112223 100112224 100112225 100112226 100112227 100112228 100112229
    100112250 100112251 100112252 100112253 100112254 100112255 100112256 100112257
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
