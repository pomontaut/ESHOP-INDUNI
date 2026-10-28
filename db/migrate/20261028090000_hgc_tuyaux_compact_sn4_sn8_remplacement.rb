class HgcTuyauxCompactSn4Sn8Remplacement < ActiveRecord::Migration[8.0]
  # HGC (hgc.ch > Tuyaux compact standard > SN4 / SN8) : les 14 anciens articles SN4 « incl.joint » sont
  # remplacés par les articles « a.manchon a.joint » L5m (SN4 Ø100-300, SN8 Ø100-250), jusqu'ici classés
  # « Tuyaux structurés standard ». Les anciens articles déjà commandés (clé étrangère order_lines) sont
  # conservés mais retirés du catalogue (sans famille). Le reste vient du seed (catalog:seed).
  OLD_REFS = %w[
    100099736 100099737 100099738 100099739 100099800 100099801 100099802
    100099284 100099803 100099804 100099805 100099806 100099807 100099808
  ].freeze
  # Lignes de nomenclature retirées (plus d'article HGC équivalent) ; les 3 autres sont repointées par le seed.
  NOMENCLATURE_REMOVED = [ [ "380300005", "100099739" ], [ "380300006", "100099800" ] ].freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    scope = Product.where(supplier_id: hgc.id, reference: OLD_REFS)
    ordered_ids = OrderLine.where(product_id: scope.select(:id)).distinct.pluck(:product_id)
    scope.where.not(id: ordered_ids).delete_all
    Product.where(id: ordered_ids).update_all(famille: nil, sous_famille: nil, sous_sous_famille: nil, equivalence_key: nil)

    return unless NomenclatureEntry.table_exists?

    NOMENCLATURE_REMOVED.each do |induni_ref, supplier_ref|
      NomenclatureEntry.where(induni_reference: induni_ref, supplier_name: "HG COMMERCIALE", supplier_reference: supplier_ref).delete_all
    end
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
