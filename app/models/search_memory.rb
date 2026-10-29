# Mémoire du moteur de recherche (bandeau de recherche) : synonymes et mots clefs supplémentaires,
# appris par l'agent « moteur de recherche » (chat administrateur). Lue par tous les utilisateurs :
# les synonymes via /api/search_memory, les mots clefs fusionnés dans `induniKeywords` de /api/products.
class SearchMemory < ApplicationRecord
  KINDS    = %w[synonym keyword].freeze
  STATUSES = %w[active suggested ignored].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :value, presence: true
  validates :term, presence: true, if: -> { kind == "synonym" }

  scope :active, -> { where(status: "active") }

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
