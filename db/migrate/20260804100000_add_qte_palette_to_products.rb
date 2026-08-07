class AddQtePaletteToProducts < ActiveRecord::Migration[8.1]
  # Canplast designations embed both an internal classification code, e.g.
  # "(A1 / 461.214)", and (on ~430 articles) a "Quantité par palette" figure
  # at the very end. The client wants the code gone from the title and the
  # palette quantity shown on its own thin line — so this pulls the palette
  # figure into its own column and refreshes designations with both stripped.
  def up
    add_column :products, :qte_palette, :string

    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    canplast = Supplier.find_by(name: "Canplast")
    return unless canplast

    items = JSON.parse(File.read(path)).select { |it| it["catalog"] == "Canplast" }

    items.each do |it|
      Product.where(supplier_id: canplast.id, reference: it["article"])
             .update_all(name: it["designation"], qte_palette: it["qtePalette"])
    end
  end

  def down
    remove_column :products, :qte_palette
  end
end
