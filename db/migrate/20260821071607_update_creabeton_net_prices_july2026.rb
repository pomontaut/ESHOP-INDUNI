class UpdateCreabetonNetPricesJuly2026 < ActiveRecord::Migration[8.1]
  # Refreshes CreaBeton unit prices from MAJ_Juillet_2026_CREABETON_avec_prix_net.xlsx
  # ("Prix net CHF" column). Matched by article reference (ArtNr); only
  # references already present in our catalog are touched — references from
  # the xlsx that we don't carry are ignored, and references we carry that
  # aren't in the xlsx (or have no net price there) are left untouched.
  # Units of measure are never modified, only unit_price.
  #
  # Done as a single bulk UPDATE ... FROM (VALUES ...) rather than one
  # update_all per reference (~1993 round trips) — over Railway's real
  # network hop to Postgres that was slow enough to blow through the
  # deploy healthcheck window and fail the whole release.
  def up
    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    creabeton = Supplier.find_by(name: "CreaBeton")
    return unless creabeton

    items = JSON.parse(File.read(path)).select { |it| it["catalog"] == "CreaBeton" }
    return if items.empty?

    items.each_slice(500) do |slice|
      values = slice.map { |it| "(#{connection.quote(it["article"])}, #{Float(it["prix"])})" }.join(",")
      execute(<<~SQL)
        UPDATE products AS p
        SET unit_price = v.column2
        FROM (VALUES #{values}) AS v
        WHERE p.supplier_id = #{creabeton.id} AND p.reference = v.column1
      SQL
    end
  end

  def down
    # Data fix only — no rollback of the previous price list.
  end
end
