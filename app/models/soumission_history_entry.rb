# Mémoire de l'agent « chiffreur soumission » : historique des positions « fourniture et pose » des
# soumissions BAT Genève 2010-2026 (db/seed_data/soumission_history.json.gz, construit par
# script/build_soumission_history.py). Sert à reconnaître une position déjà rencontrée (nombre de fois,
# années, unité et quantité habituelles, « fourniture et pose » probable). Aucun prix.
require "zlib"
require "json"

class SoumissionHistoryEntry < ApplicationRecord
  SEED_PATH = Rails.root.join("db/seed_data/soumission_history.json.gz")
  MIN_SIMILARITY = 0.6
  MIN_COMMON_WORDS = 2 # mots communs non numériques (évite « DN/OD 200. » ↔ tout ce qui contient 200)
  MAX_RESULTS = 3

  # Le fichier JSON est la source de vérité (table sans clé étrangère, rechargée en entier).
  def self.seed_from_json!(path = SEED_PATH)
    return unless File.exist?(path)
    rows = JSON.parse(Zlib::GzipReader.open(path, &:read))
    now = Time.current
    records = rows.map do |r|
      norm = SearchMemory.norm(r["t"])
      { designation: r["t"], norm_text: norm, tokens: tokenize(r["t"]).join(" "), code: r["c"].presence, unit: r["u"].to_s,
        heading: r["h"].presence, scope: r["s"], occurrences: r["n"], affaires_count: r["na"], year_from: r["y0"], year_to: r["y1"],
        sample_affaire: r["a"], median_quantity: r["q"], created_at: now, updated_at: now }
    end.uniq { |r| [ r[:norm_text], r[:unit] ] }
    transaction do
      delete_all
      records.each_slice(1000) { |slice| insert_all(slice) }
    end
    reset_index!
    records.size
  end

  STOPWORDS = SoumissionPricer::STOPWORDS
  def self.tokenize(text)
    SearchMemory.norm(text).split.reject { |w| w.length < 2 || STOPWORDS.include?(w) }
      .map { |w| w.length > 3 && w.end_with?("s") ? w.chomp("s") : w }.to_set
  end

  def self.reset_index! = (@index = nil)

  # Index en mémoire (jeton → entrées) ; ~31'000 lignes, construit une fois par processus.
  def self.index
    @index ||= begin
      entries = pluck(:id, :designation, :tokens, :code, :unit, :heading, :scope, :occurrences, :affaires_count, :year_from, :year_to,
                      :sample_affaire, :median_quantity).map do |id, d, t, c, u, h, s, n, na, y0, y1, a, q|
        { id: id, designation: d, tokens: t.split.to_set, code: c, unit: u, heading: h, scope: s, n: n, na: na, y0: y0, y1: y1, affaire: a, qty: q&.to_f }
      end
      inverted = Hash.new { |h, k| h[k] = [] }
      entries.each { |e| e[:tokens].each { |t| inverted[t] << e } }
      { entries: entries, inverted: inverted }
    end
  end

  # Positions historiques proches de la désignation (part des mots communs, nombres = poids double,
  # symétrique : on compare à la fois à la position et à l'entrée pour éviter les entrées trop longues).
  def self.similar(designation, unit: nil)
    query = tokenize(designation)
    return [] if query.empty?
    idx = index
    candidates = query.flat_map { |t| idx[:inverted][t] || [] }.uniq
    scored = candidates.filter_map do |e|
      common = query & e[:tokens]
      next if common.count { |t| !t.match?(/\d/) } < MIN_COMMON_WORDS
      w = ->(set) { set.sum { |t| t.match?(/\d/) ? 2.0 : 1.0 } }
      s = 2 * w.(common) / (w.(query) + w.(e[:tokens]))
      s += 0.05 if unit.present? && SoumissionPricer.normalize_unit(unit) == SoumissionPricer.normalize_unit(e[:unit])
      [ e, s ] if s >= MIN_SIMILARITY
    end
    scored.sort_by { |e, s| [ -s, -e[:n] ] }.first(MAX_RESULTS)
  end
end
