class AddHgcAutreTubeSouple < ActiveRecord::Migration[8.1]
  # Nouvelle rubrique HGC « Protection Câbles › Tubes de protection › Autre tube souple » :
  # tuyaux prot.câble LDPE a.ferme.profile-L Ø80 à Ø200 mm, L5m et L10m (9 articles) + les
  # deux K100/K120 PELD « a. fermet-L » Swisscom déjà au catalogue (100053925/927), déplacés
  # depuis « PE câble Swisscom » avec prix mis à jour (upsert). Aucune équivalence_key.
  # 100091983 : « 112/120 » sur hgc.ch = 132/120 (poids 24.8 kg, prix = 100075285).
  REFERENCES = %w[
    100033841 100033845 100033977 100075283 100075284 100075285 100075286 100091983 100091984
    100053925 100053927
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
