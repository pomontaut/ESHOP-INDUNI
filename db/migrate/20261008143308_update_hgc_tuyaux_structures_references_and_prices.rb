class UpdateHgcTuyauxStructuresReferencesAndPrices < ActiveRecord::Migration[8.1]
  # The "Tuyaux structurés standard" family (HGC, Canalisations PVC) only had
  # 5 seeded references (SN2 Ø100/125/150/200/350mm). Checked against the
  # live catalog page for this family: Ø150/200mm are listed there under
  # different references and different (higher) prices, and SN4/SN8 and
  # several more SN2 diameters aren't seeded at all yet. Ø100/125mm aren't
  # shown on the page provided and are left untouched.
  #
  # Ø350mm (100022512) already matches exactly (reference and price) and
  # needs no change.
  RETIRED_REFERENCES = %w[100022729 100022771].freeze

  NEW_REFERENCES = %w[
    100063110 100063111 100063112 100063113 100124017
    100063068 100063069 100072421 100072422 100072423 100072424 100124018
    100073688 100073689 100067724 100067725 100067726 100124019
  ].freeze

  def up
    hgc = Supplier.find_by(name: "HGC")
    return unless hgc

    # A discontinued reference still referenced by a past order must be kept
    # (deleting it violates the order_lines foreign key and aborts every
    # subsequent boot).
    Product.where(supplier_id: hgc.id, reference: RETIRED_REFERENCES)
           .where.not(id: OrderLine.select(:product_id))
           .delete_all

    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    items = JSON.parse(File.read(path)).select do |it|
      it["catalog"] == "HGC" && NEW_REFERENCES.include?(it["article"])
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
        image:             it["image"],
        poids_kg:          it["poids"],
        created_at:        now,
        updated_at:        now
      }
    end.uniq { |r| [ r[:supplier_id], r[:reference] ] }

    rows.each_slice(500) do |slice|
      Product.upsert_all(slice, unique_by: :index_products_on_supplier_id_and_reference)
    end
  end

  def down
    # Data refresh only — no rollback of catalog contents.
  end
end
