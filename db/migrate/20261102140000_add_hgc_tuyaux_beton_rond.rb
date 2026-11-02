class AddHgcTuyauxBetonRond < ActiveRecord::Migration[8.1]
  # HGC « Préfa-béton › Tuyaux & bordures béton › Tuyaux béton rond » : 48 tuyaux en béton non armé
  # Ø100–2000 mm (hgc.ch, prix nets). Doublons supprimés : les anciens D100/D80/D60 L100cm (mêmes
  # dimensions que 100014998 / 100014993 / 100014955). Une référence déjà commandée est gardée hors catalogue.
  REFERENCES = %w[
    100014877 100014913 100014917 100014951 100015040 100015385 100015481 100015518 100015594
    100015640 100015645 100015691 100015697 100015741 100015743 100015745 100015747 100015865
    100015867 100015869 100015911 100015919 100015961 100015966 100016008 100014870 100014873
    100014875 100014879 100014911 100014915 100014919 100014953 100014955 100014959 100014991
    100014993 100014996 100014998 100015042 100015044 100015046 100015048 100015093 100015095
    100015099 100015121 100015123
  ].freeze
  DUPLICATES = %w[100097269 100097311 100097313].freeze

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

    scope = Product.where(supplier_id: hgc.id, reference: DUPLICATES)
    ordered_ids = OrderLine.where(product_id: scope.select(:id)).distinct.pluck(:product_id)
    scope.where.not(id: ordered_ids).delete_all
    Product.where(id: ordered_ids).update_all(famille: nil, sous_famille: nil, sous_sous_famille: nil, equivalence_key: nil)
  end

  def down
    # Data refresh only — no rollback of catalog contents.
  end
end
