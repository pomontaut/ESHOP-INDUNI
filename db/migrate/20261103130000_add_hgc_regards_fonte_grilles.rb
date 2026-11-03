class AddHgcRegardsFonteGrilles < ActiveRecord::Migration[8.1]
  # HGC « Fonte / Regard de voirie » : grilles nid d'abeille Fig.2815/2805, siphons de sol
  # Fig.1600/1601 et regards BGS Fig.111/115 (hgc.ch, prix nets, photo HGC).
  # Upsert par référence : pas de doublon.
  FAMILLE = "Voirie & Aménagement".freeze
  ANCIENNE = "Voirie".freeze
  NOUVELLE = "Fonte / Regard de voirie".freeze
  REFERENCES = %w[
    100005257 100005259 100005291 100005293 100005295 100005297 100140389
    100006413 100006415 100006417 100006419 100006461 100006463 100006465
    100006467 100007638 100007662 100007664 100007666 100007710 100007714
    100008078 100008120 100008122 100008124 100008126 100008128 100008170
    100008265 100101992
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
