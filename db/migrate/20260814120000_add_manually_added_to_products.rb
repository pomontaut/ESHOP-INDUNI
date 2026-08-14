class AddManuallyAddedToProducts < ActiveRecord::Migration[8.1]
  def change
    # Marks products created live from the app (e.g. confirmed from a devis
    # import) rather than sourced from db/seed_data/catalog_products.json.
    # catalog:seed's full-refresh cleanup for HGC/Leuba HIAG deletes any
    # product whose reference isn't in the current JSON file — this flag
    # excludes manually-added rows from that cleanup so they aren't silently
    # wiped out on the next deploy. It's reset to false automatically if the
    # same reference later appears in a JSON update (see catalog_seed.rake),
    # at which point the row is treated as a normal catalog entry again.
    add_column :products, :manually_added, :boolean, default: false, null: false
  end
end
