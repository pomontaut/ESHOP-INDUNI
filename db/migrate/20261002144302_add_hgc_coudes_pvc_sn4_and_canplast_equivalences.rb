class AddHgcCoudesPvcSn4AndCanplastEquivalences < ActiveRecord::Migration[8.1]
  # Refresh of HGC's "coude PVC dur KGB" catalog page (public site, not the
  # tariff PDF): the 11 previously-seeded codes for these elbows used stale
  # references/prices and an unclassified __DIRECT__ sub-family. They are
  # replaced by the current codes below (15°/30°/45°/90°, Ø100-300mm),
  # reclassified under Canalisations PVC / Coudes / Coude standard SN4 to
  # match Canplast's own taxonomy, and linked to their Canplast SN4
  # equivalent (matched by nominal diameter) via equivalence_key.
  #
  # 87° (ex-100098799/100098804) is intentionally left untouched: Canplast's
  # SN4 line has no 87° variant, and no replacement data was provided for it.
  RETIRED_REFERENCES = %w[
    100098782 100098784 100098785 100098786
    100098789 100098791
    100098793 100098794 100098795 100098796 100098798
  ].freeze

  NEW_REFERENCES = %w[
    100099794 100099820 100099822 100099826 100099830 100099833
    100099795 100099821 100099823 100099827 100099831 100099834
    100099796 100099799 100099824 100099828 100099832 100099835
    100084977 100084978 100084979 100084980 100084981 100084982
  ].freeze

  DIAM_TO_CANPLAST_OD = { 100 => 110, 125 => 125, 150 => 160, 200 => 200, 250 => 250, 300 => 315 }.freeze

  def up
    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    hgc = Supplier.find_by(name: "HGC")
    canplast = Supplier.find_by(name: "Canplast")
    return unless hgc

    Product.where(supplier_id: hgc.id, reference: RETIRED_REFERENCES).delete_all

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

    return unless canplast

    diam_angle = NEW_REFERENCES.each_with_object({}) do |ref, acc|
      it = items.find { |i| i["article"] == ref }
      next unless it

      m = it["designation"].match(/(\d+)°.*Ø(\d+)mm/)
      next unless m

      angle, diam = m[1].to_i, m[2].to_i
      od = DIAM_TO_CANPLAST_OD[diam]
      next unless od

      acc[format("LDC%03d%02d", od, angle)] = ref
    end

    diam_angle.each do |canplast_ref, hgc_ref|
      Product.where(supplier_id: canplast.id, reference: canplast_ref)
             .update_all(equivalence_key: hgc_ref)
    end
  end

  def down
    # Data refresh only — no rollback of catalog contents.
  end
end
