class AddHgcAnneauxCentub < ActiveRecord::Migration[8.1]
  # HGC « Préfa-béton › Anneau » : 12 anneaux de regard CENTUB non armés (Ø800/1000/1200, hgc.ch), prix nets.
  REFERENCES = %w[100016868 100016900 100016902 100016904 100016906 100016908 100016950 100016952 100112794 100112795 100112796 100112797].freeze

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
