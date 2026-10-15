# Fusionne plusieurs fiches fournisseur qui désignent en réalité le même
# fournisseur (ex. « HGC » et « HG COMMERCIALE », même numéro 230977 :
# `suppliers:import` renomme la fiche par numéro fournisseur, puis
# `catalog:seed` recrée « HGC » par son nom) en une seule fiche.
#
# - La fiche conservée porte le nom `target_name` (créée/renommée au besoin).
# - Articles : pour une même référence (comparée sans espaces ni casse), c'est
#   l'article le plus récemment modifié qui écrase les autres ; les lignes de
#   commande des doublons supprimés sont rattachées à l'article conservé.
# - Commandes, accès utilisateurs (`allowed_suppliers`) et coordonnées vides
#   sont repris sur la fiche conservée.
# Idempotent : sans doublon, ne fait que s'assurer du nom.
class SupplierMerger
  FILLABLE_SUPPLIER_ATTRS = %w[
    address city country_code email email_fribourg email_geneve email_jura email_valais email_vaud
    fax ide_number payment_condition phone postal_code responsable_achat supplier_number
  ].freeze
  FILLABLE_PRODUCT_ATTRS = %w[image equivalence_key poids_kg qte_palette descriptif].freeze

  def self.merge!(target_name:, source_names:)
    new(target_name, source_names).merge!
  end

  def initialize(target_name, source_names)
    @target_name = target_name
    @names = ([ target_name ] + Array(source_names)).map { |n| n.to_s.strip.downcase }
  end

  def merge!
    suppliers = Supplier.where("lower(trim(name)) IN (?)", @names).order(:id).to_a
    return if suppliers.empty?

    old_names = suppliers.map(&:name)
    survivor = suppliers.find { |s| s.name.to_s.strip.casecmp?(@target_name) } || suppliers.first
    others = suppliers - [ survivor ]

    Supplier.transaction do
      others.each { |other| absorb(survivor, other) }
      merge_duplicate_references(survivor)
      survivor.update_columns(name: @target_name) if survivor.name != @target_name
      rename_in_user_access(old_names)
    end
  end

  private

  def absorb(survivor, other)
    FILLABLE_SUPPLIER_ATTRS.each do |attr|
      survivor[attr] = other[attr] if survivor[attr].blank? && other[attr].present?
    end
    survivor.confidential_pricing ||= other.confidential_pricing
    survivor.save!(validate: false) if survivor.changed?

    Order.where(supplier_id: other.id).update_all(supplier_id: survivor.id)
    # Déplace sans conflit : les références en double sont résolues juste après
    # (index unique supplier_id+reference), on commence donc par supprimer les
    # perdants parmi les deux fiches.
    resolve_duplicates(survivor, Product.where(supplier_id: [ survivor.id, other.id ]).to_a)
    Product.where(supplier_id: other.id).update_all(supplier_id: survivor.id)
    Supplier.where(id: other.id).delete_all
  end

  # Doublons de références déjà présents à l'intérieur de la fiche conservée
  # (ex. « ABC 1 » / « abc1 » …) : même règle, le plus récent gagne.
  def merge_duplicate_references(survivor)
    resolve_duplicates(survivor, Product.where(supplier_id: survivor.id).to_a)
  end

  def resolve_duplicates(survivor, products)
    products.group_by { |p| normalize(p.reference) }.each_value do |group|
      next if group.size < 2

      winner = group.max_by { |p| [ p.updated_at.to_f, p.id ] }
      (group - [ winner ]).each do |loser|
        FILLABLE_PRODUCT_ATTRS.each do |attr|
          winner[attr] = loser[attr] if winner[attr].blank? && loser[attr].present?
        end
        OrderLine.where(product_id: loser.id).update_all(product_id: winner.id)
        Product.where(id: loser.id).delete_all
      end
      winner.supplier_id = survivor.id
      winner.reference = winner.reference.to_s.strip
      winner.save!(validate: false) if winner.changed?
    end
  end

  def normalize(reference)
    reference.to_s.strip.upcase
  end

  def rename_in_user_access(old_names)
    old = old_names.map { |n| n.to_s.strip.downcase }.uniq - [ @target_name.downcase ]
    User.find_each do |user|
      list = user.allowed_suppliers
      next if list.blank?
      updated = list.map { |n| old.include?(n.to_s.strip.downcase) ? @target_name : n }.uniq
      user.update_columns(allowed_suppliers: updated) if updated != list
    end
  end
end
