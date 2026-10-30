class AddHgcStabilTwin < ActiveRecord::Migration[8.1]
  # Nouvelle rubrique HGC « Protection Câbles › Tubes de protection › Stabil-Twin (double
  # paroi) » : tubes PE ondulés double paroi rouge / bleu / jaune, Ø31/40 à Ø107/125 mm,
  # rouleaux de 50 m (10 articles hgc.ch). Aucune équivalence_key posée.
  REFERENCES = %w[
    100067648 100067682 100101818 100101890 100101891
    100067649 100067680 100101819 100124021 100124022
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
