class RefreshHgcLeubaCanplastCatalogAndDropSikaAlzo < ActiveRecord::Migration[8.1]
  # HGC and Leuba HIAG are treated as a full refresh (their sheet covers ~99%
  # of the known catalog, so items missing from it are discontinued).
  # Canplast only appears in the sheet as equivalence annotations for a
  # handful of HGC items, so it is update-only: nothing is removed.
  FULL_REFRESH_CATALOGS = [ "HGC", "Leuba HIAG" ].freeze

  # In case this runs on a database bootstrapped via db:schema:load (which
  # skips the data-seeding side effects of earlier migrations), make sure
  # the 3 surviving suppliers exist so the catalog below has somewhere to go.
  REQUIRED_SUPPLIERS = {
    "HGC" => { email: "yannick.mace@hgc.ch", phone: "0041 22 343 85 50" },
    "Canplast" => { email: "commandes@canplast.ch", phone: "0041 21 637 37 77" },
    "Leuba HIAG" => { email: "william.bouquet@leubahiag.ch", phone: "0041 58 470 66 66" }
  }.freeze

  def up
    Supplier.where(name: [ "Sika", "Alzo" ]).find_each do |supplier|
      supplier.products.delete_all
      supplier.destroy
    end

    REQUIRED_SUPPLIERS.each do |name, attrs|
      Supplier.find_or_create_by!(name: name) { |s| s.assign_attributes(attrs) }
    end

    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    supplier_ids = Supplier.where(name: [ "HGC", "Canplast", "Leuba HIAG" ]).pluck(:name, :id).to_h
    items = JSON.parse(File.read(path)).select { |it| supplier_ids.key?(it["catalog"]) }
    now = Time.current

    rows = items.map do |it|
      {
        supplier_id:       supplier_ids[it["catalog"]],
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
        created_at:        now,
        updated_at:        now
      }
    end

    # Guard against duplicate (supplier_id, reference) pairs in the seed data:
    # upsert_all's ON CONFLICT DO UPDATE raises PG::CardinalityViolation if the
    # same conflict target appears twice in a single statement.
    rows = rows.uniq { |r| [ r[:supplier_id], r[:reference] ] }

    rows.each_slice(500) do |slice|
      Product.upsert_all(slice, unique_by: :index_products_on_supplier_id_and_reference)
    end

    FULL_REFRESH_CATALOGS.each do |catalog|
      supplier_id = supplier_ids[catalog]
      next unless supplier_id

      current_refs = items.select { |it| it["catalog"] == catalog }.map { |it| it["article"] }.to_set
      Product.where(supplier_id: supplier_id).where.not(reference: current_refs.to_a).delete_all
    end
  end

  def down
    # Data refresh only — no rollback of catalog contents.
  end
end
