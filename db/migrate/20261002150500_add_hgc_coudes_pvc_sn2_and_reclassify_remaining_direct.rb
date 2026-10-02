class AddHgcCoudesPvcSn2AndReclassifyRemainingDirect < ActiveRecord::Migration[8.1]
  # 1) Finish reclassifying HGC "coude" articles that were still under the
  #    generic __DIRECT__ sub-family, matching Canplast's own nomenclature
  #    (never introducing a sub-family that would be empty on the HGC side):
  #    - The two SN4 87° KGB elbows (not touched by the previous migration,
  #      since no price/reference/equivalence update was wanted for them)
  #      belong to the same "Coude standard SN4" range as the other KGB
  #      elbows.
  #    - Three "Protection Câbles" conduit elbows matched to Canplast's
  #      "Coude flexible long" (90°, manchonné) and "Coude K-série" (K55,
  #      R=600mm, fixed radius) by comparing diameter/radius/angle.
  RECLASSIFY = {
    "100098799" => "Coude standard SN4",
    "100098804" => "Coude standard SN4",
    "100033489" => "Coude flexible long",
    "100033515" => "Coude flexible long",
    "100053954" => "Coude K-série"
  }.freeze

  # 2) New HGC "coude PVC dur KGB" SN2 articles (Ø100-500mm, 15°/30°/45°/90°,
  #    public catalog page). Ø100-300mm has no Canplast SN2 equivalent
  #    (Canplast's SN2 range only starts at Ø355mm — the gap between its SN4
  #    line, which stops at Ø315mm, and its SN2 line is a real gap in their
  #    catalog, not a classification error), so only Ø350/400/500mm get an
  #    equivalence_key.
  NEW_REFERENCES = %w[
    100095519 100095570 100095571 100095572 100095573 100095574 100024056
    100095575 100095576 100095577 100095578 100095579 100095580 100023481
    100095581 100095582 100095583 100095584 100095585 100095586 100023570 100095587
    100095592 100095593 100095594 100095595 100095596 100095597 100023667 100101860 100024054
  ].freeze

  CANPLAST_EQUIVALENCES = {
    "LDC35515" => "100024056",
    "LDC35530" => "100023481",
    "LDC35545" => "100023570",
    "LDC40045" => "100095587",
    "LDC35590" => "100023667",
    "LDC40090" => "100101860",
    "LDC50090" => "100024054"
  }.freeze

  def up
    hgc = Supplier.find_by(name: "HGC")
    return unless hgc

    RECLASSIFY.each do |reference, sous_sous_famille|
      Product.where(supplier_id: hgc.id, reference: reference)
             .update_all(sous_sous_famille: sous_sous_famille)
    end

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
        equivalence_key:   it["equivalenceKey"],
        created_at:        now,
        updated_at:        now
      }
    end.uniq { |r| [ r[:supplier_id], r[:reference] ] }

    rows.each_slice(500) do |slice|
      Product.upsert_all(slice, unique_by: :index_products_on_supplier_id_and_reference)
    end

    canplast = Supplier.find_by(name: "Canplast")
    return unless canplast

    CANPLAST_EQUIVALENCES.each do |canplast_ref, hgc_ref|
      Product.where(supplier_id: canplast.id, reference: canplast_ref)
             .update_all(equivalence_key: hgc_ref)
    end
  end

  def down
    # Data refresh only — no rollback of catalog contents.
  end
end
