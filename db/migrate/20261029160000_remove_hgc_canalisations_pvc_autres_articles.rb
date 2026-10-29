class RemoveHgcCanalisationsPvcAutresArticles < ActiveRecord::Migration[8.0]
  # Catégorie « Canalisations PVC > Autres articles » HGC supprimée à la demande du propriétaire
  # (29 références : arrosage, Enkadrain/Delta-Terraxx, siphons, grille de ventilation, drainage flexible
  # HDPE…). Les regards en fonte sont déjà passés en Voirie. Une référence déjà commandée (clé étrangère
  # order_lines) est conservée mais sortie du catalogue (sans famille ni équivalence). Le lien Canplast
  # FLTPE110 ↔ 100037467 disparaît avec elle.
  OLD_REFERENCES = %w[
    100001819 100001851 100001859 100001963 100001969 100002022 100002120 100002180
    100002187 100002231 100006411 100006415 100006465 100013799 100013851 100016759
    100037467 100045336 100046517 100046519 100046561 100046657 100051224 100054289
    100054418 100054464 100059031 100062871 100068660
  ].freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    scope = Product.where(supplier_id: hgc.id, reference: OLD_REFERENCES)
    ordered_ids = OrderLine.where(product_id: scope.select(:id)).distinct.pluck(:product_id)
    scope.where.not(id: ordered_ids).delete_all
    Product.where(id: ordered_ids).update_all(famille: nil, sous_famille: nil, sous_sous_famille: nil, equivalence_key: nil)
    canplast = Supplier.find_by(name: "Canplast")
    Product.where(supplier_id: canplast.id, equivalence_key: OLD_REFERENCES).update_all(equivalence_key: nil) if canplast
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
