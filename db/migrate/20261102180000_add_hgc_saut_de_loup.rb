class AddHgcSautDeLoup < ActiveRecord::Migration[8.1]
  # HGC « Préfa-béton › Saut de loup » : 46 sauts-de-loup armés LW (120x80, 120x70) et FAKO
  # (80/60, 80/80, 100/60, 120/60, 120/80, 140/80, 170/80, 210/80), hgc.ch, prix nets.
  REFERENCES = %w[
    100014566 100014568 100014564 100014600 100014602 100014462 100014464 100014466 100014468
    100013403 100013405 100013407 100013409 100013451 100013611 100013747 100013709 100078150
    100078151 100078153 100078155 100078166 100078039 100078091 100078093 100078094 100078096
    100078098 100078071 100078073 100078074 100078076 100078078 100078122 100078123 100078124
    100078125 100078126 100078127 100078133 100078134 100078135 100078136 100078137 100078138
    100078145
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
