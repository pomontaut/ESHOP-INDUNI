class RemoveHgcCoudesPvcDimensionDuplicates < ActiveRecord::Migration[8.0]
  # Doublons dimensionnels des coudes PVC dur KGB HGC (même angle + même diamètre sous deux
  # références) : on ne garde que les références 1000955xx / 1001017xx / 10002xxxx (catalogue HGC
  # confirmé par le propriétaire) ; les 24 anciennes (1000997xx-1000998xx, 1000849xx) sont retirées.
  # Une ancienne référence déjà commandée (clé étrangère order_lines) est conservée mais sortie
  # du catalogue (sans famille ni équivalence). Les 87° (100098799/804) ne sont pas des doublons.
  OLD_REFERENCES = %w[
    100099794 100099820 100099822 100099826 100099830 100099833
    100099795 100099821 100099823 100099827 100099831 100099834
    100099796 100099799 100099824 100099828 100099832 100099835
    100084977 100084978 100084979 100084980 100084981 100084982
  ].freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    scope = Product.where(supplier_id: hgc.id, reference: OLD_REFERENCES)
    ordered_ids = OrderLine.where(product_id: scope.select(:id)).distinct.pluck(:product_id)
    scope.where.not(id: ordered_ids).delete_all
    Product.where(id: ordered_ids).update_all(famille: nil, sous_famille: nil, sous_sous_famille: nil, equivalence_key: nil)
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
