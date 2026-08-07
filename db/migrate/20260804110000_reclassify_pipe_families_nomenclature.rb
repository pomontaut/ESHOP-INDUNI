class ReclassifyPipeFamiliesNomenclature < ActiveRecord::Migration[8.1]
  # Applies the same real-product-type nomenclature used for Canplast PVC
  # (sous-famille = product type, sous-sous-famille = jointing/variant
  # detail derived from the designation, instead of a generic SN-rating
  # bucket) to the other pipe/fitting families: Canplast PE/HDPE, Canplast
  # PP, Canplast Protection Câbles, and HGC Drainage & Canalisation. The
  # previous buckets mixed unrelated product types (e.g. reductions and
  # pipes both sitting under "Embranchements") because they were grouped by
  # SN rating rather than by what the article actually is.
  def up
    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    targets = [
      [ "Canplast", "Canalisations PE/HDPE" ],
      [ "Canplast", "Canalisations PP" ],
      [ "Canplast", "Protection Câbles" ],
      [ "HGC", "Drainage & Canalisation" ]
    ]

    supplier_ids = Supplier.where(name: targets.map(&:first).uniq).pluck(:name, :id).to_h
    all_items = JSON.parse(File.read(path))

    targets.each do |catalog, famille|
      supplier_id = supplier_ids[catalog]
      next unless supplier_id

      items = all_items.select { |it| it["catalog"] == catalog && it["famille"] == famille }
      items.each do |it|
        Product.where(supplier_id: supplier_id, reference: it["article"])
               .update_all(sous_famille: it["sousFamille"], sous_sous_famille: it["sousSousFamille"])
      end
    end
  end

  def down
    # Data fix only — no rollback of the previous grouping.
  end
end
