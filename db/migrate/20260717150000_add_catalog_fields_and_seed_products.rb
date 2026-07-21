class AddCatalogFieldsAndSeedProducts < ActiveRecord::Migration[8.1]
  def up
    add_column :products, :descriptif, :text
    add_column :products, :unite, :string
    add_column :products, :famille, :string
    add_column :products, :sous_famille, :string
    add_column :products, :sous_sous_famille, :string
    add_column :products, :icone, :string
    add_column :products, :image, :string
    add_index :products, [ :supplier_id, :reference ], unique: true, name: "index_products_on_supplier_id_and_reference"

    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    supplier_ids = Supplier.where(name: [ "HGC", "Sika", "Canplast", "Alzo", "Leuba HIAG" ]).pluck(:name, :id).to_h
    items = JSON.parse(File.read(path))
    now = Time.current

    rows = items.filter_map do |it|
      supplier_id = supplier_ids[it["catalog"]]
      next unless supplier_id
      {
        supplier_id:       supplier_id,
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

    rows.each_slice(500) do |slice|
      Product.upsert_all(slice, unique_by: :index_products_on_supplier_id_and_reference)
    end
  end

  def down
    remove_index :products, name: "index_products_on_supplier_id_and_reference"
    remove_column :products, :descriptif
    remove_column :products, :unite
    remove_column :products, :famille
    remove_column :products, :sous_famille
    remove_column :products, :sous_sous_famille
    remove_column :products, :icone
    remove_column :products, :image
  end
end
