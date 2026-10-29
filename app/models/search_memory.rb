# Mémoire du moteur de recherche (bandeau de recherche) : synonymes et mots clefs supplémentaires,
# appris par l'agent « moteur de recherche » (chat administrateur). Lue par tous les utilisateurs :
# les synonymes via /api/search_memory, les mots clefs fusionnés dans `induniKeywords` de /api/products.
class SearchMemory < ApplicationRecord
  KINDS    = %w[synonym keyword rule rule_off].freeze
  STATUSES = %w[active suggested ignored].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :value, presence: true
  validates :term, presence: true, if: -> { %w[synonym rule].include?(kind) }

  scope :active, -> { where(status: "active") }

  # Règles de classement intégrées (modifiables par l'agent : désactivables, remplaçables). Une règle ajoute
  # `points` au score d'un article quand : l'article contient un des mots de `product_has_any` (désignation,
  # descriptif, familles — pas les mots clefs), la requête ne contient AUCUN mot de `query_lacks_any` et
  # contient au moins un mot de `query_has_any` (si renseigné). Mots comparés sans accents ni pluriel.
  DEFAULT_RULES = [
    { id: "b-drainage", label: "Tuyau de drainage / perforé après les tuyaux pleins quand la requête ne parle pas de drainage",
      product_has_any: %w[drainage drain perfore fente fentes], query_lacks_any: %w[drain drainage drains perfore fente fentes drainant filtrant], query_has_any: [], points: -120 },
    { id: "b-structure", label: "Tuyau structuré après le compact quand la requête demande du compact",
      product_has_any: %w[structure structuree], query_lacks_any: %w[structure structuree], query_has_any: %w[compact], points: -100 }
  ].freeze

  # Règles actives pour le navigateur : intégrées (sauf désactivées) + règles apprises.
  def self.rules_json
    off = where(kind: "rule_off").pluck(:value)
    builtin = DEFAULT_RULES.reject { |r| off.include?(r[:id]) }.map { |r| r.merge(builtin: true) }
    learned = active.where(kind: "rule").order(:id).filter_map do |m|
      r = JSON.parse(m.value).symbolize_keys
      r.merge(id: "m#{m.id}", label: m.term, builtin: false)
    rescue JSON::ParserError
      nil
    end
    builtin + learned
  end

  def self.norm(s)
    ActiveSupport::Inflector.transliterate(s.to_s).downcase.gsub(/[^a-z0-9]+/, " ").strip
  end

  def self.split_list(s)
    s.to_s.split(/[,;\n|]/).map(&:strip).reject(&:blank?)
  end

  # Synonymes actifs, pour le navigateur : [{ term:, values: [..], oneWay: }]
  def self.synonyms_json
    active.where(kind: "synonym").order(:id).map { |m| { id: m.id, term: m.term, values: split_list(m.value), oneWay: m.one_way } }
  end

  # { [fournisseur, référence] => "mots clefs ajoutés" } pour les mots clefs actifs (cible INDUNI → toutes ses lignes).
  def self.keywords_by_product
    out = Hash.new { |h, k| h[k] = [] }
    rows = active.where(kind: "keyword").to_a
    induni_refs = rows.filter_map(&:induni_reference).uniq
    lines = induni_refs.empty? ? {} : NomenclatureEntry.where(induni_reference: induni_refs).group_by(&:induni_reference)
    rows.each do |m|
      if m.induni_reference.present?
        (lines[m.induni_reference] || []).each { |e| out[[ e.supplier_name, e.supplier_reference ]] << m.value }
      elsif m.supplier_name.present?
        out[[ m.supplier_name, m.supplier_reference ]] << m.value
      end
    end
    out.transform_values { |v| v.join(" ; ") }
  end
end
