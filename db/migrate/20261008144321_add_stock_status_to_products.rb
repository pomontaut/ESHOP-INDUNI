class AddStockStatusToProducts < ActiveRecord::Migration[8.1]
  # Marqueur délai transmis article par article (pas une détection de stock
  # automatique) : "stock" affiche un badge vert (livraison théorique sous
  # 24h ouvrées si commandé avant 10h), "sur_demande" un badge orange (délai
  # à confirmer par le fournisseur). Null = pas d'information connue, aucun
  # badge affiché plutôt qu'une supposition.
  def up
    add_column :products, :stock_status, :string

    hgc = Supplier.find_by(name: "HGC")
    return unless hgc

    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    items = JSON.parse(File.read(path)).select do |it|
      it["catalog"] == "HGC" && it["stockStatus"].present?
    end

    items.each do |it|
      Product.where(supplier_id: hgc.id, reference: it["article"])
             .update_all(stock_status: it["stockStatus"])
    end
  end

  def down
    remove_column :products, :stock_status
  end
end
