class AddHgcRegardsFonteBgsAco < ActiveRecord::Migration[8.1]
  # HGC « Fonte / Regard de voirie » : regards C250 Fig.2630, BGS Fig.131/135/136 et ACO
  # C250 sur tuyau (hgc.ch, prix nets, photo HGC). Upsert par référence : pas de doublon.
  FAMILLE = "Voirie & Aménagement".freeze
  ANCIENNE = "Voirie".freeze
  NOUVELLE = "Fonte / Regard de voirie".freeze
  REFERENCES = %w[
    100140469 100129076 100008505 100007760 100007762 100007920 100007922
    100007924 100007926 100007970 100008405 100008407 100008409 100008501
    100008701 100008705 100071172 100071173 100083669 100133551 100133552
    100133553 100002687 100002689 100002731 100002733 100065291
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
        supplier_id: hgc.id, reference: it["article"], name: it["designation"],
        unit_price: it["prix"], descriptif: it["descriptif"], unite: it["unite"],
        famille: it["famille"], sous_famille: it["sousFamille"],
        sous_sous_famille: it["sousSousFamille"], icone: it["icone"],
        poids_kg: it["poids"], image: it["image"], created_at: now, updated_at: now
      }
    end
    Product.upsert_all(rows, unique_by: :index_products_on_supplier_id_and_reference) if rows.any?
  end

  def down
    # Data refresh only — no rollback of catalog contents.
  end
end
