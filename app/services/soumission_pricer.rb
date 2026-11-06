# Agent « chiffreur soumission » (environnement Développement) : pour chaque position de soumission,
# propose les meilleurs articles des catalogues avec prix et total. Déterministe (aucun appel de modèle),
# nourri par la mémoire existante : synonymes et mots clefs du moteur de recherche (SearchMemory),
# mots clefs INDUNI (NomenclatureEntry) et rapprochements validés par les utilisateurs (SoumissionMatch).
# Prix confidentiels (Sika…) : JAMAIS exposés (prix nil, mention « accords cadre »).
class SoumissionPricer
  STOPWORDS = %w[de le la les du des en et ou pour avec sans par au aux un une sur dans a l d y].freeze
  MIN_SCORE = 0.6
  MAX_CANDIDATES = 3
  UNIT_ALIASES = { "m2" => "m2", "m²" => "m2", "m3" => "m3", "m³" => "m3", "ml" => "ml", "m" => "ml", "pce" => "pce", "pc" => "pce",
                   "pcs" => "pce", "p" => "pce", "u" => "pce", "pièce" => "pce", "piece" => "pce", "pieces" => "pce", "kg" => "kg", "t" => "t",
                   "paquet" => "paquet", "pqt" => "paquet", "rouleau" => "rouleau", "rlx" => "rouleau", "m1" => "ml" }.freeze

  def initialize(scope: Product.joins(:supplier).includes(:supplier).where("products.unit_price > 0 OR suppliers.confidential_pricing = ?", true))
    @products = scope.where.not(famille: nil).to_a
    keywords = SearchMemory.keywords_by_product
    induni = NomenclatureEntry.where.not(search_keywords: [ nil, "" ]).pluck(:supplier_name, :supplier_reference, :search_keywords)
                              .each_with_object({}) { |(s, r, k), h| h[[ s, r ]] = k }
    @tokens = @products.to_h do |p|
      text = [ p.name, p.descriptif, p.famille, p.sous_famille, p.reference, induni[[ p.supplier.name, p.reference ]],
               keywords[[ p.supplier.name, p.reference ]]&.join(" ") ].join(" ")
      [ p.id, tokenize(text) ]
    end
    @synonyms = SearchMemory.synonyms_json.flat_map do |s|
      term = tokenize(s[:term]).to_a
      vals = Array(s[:values]).flat_map { |v| tokenize(v).to_a }
      pairs = term.product(vals).map { |t, v| [ t, v ] }
      s[:oneWay] ? pairs : pairs + pairs.map(&:reverse)
    end.group_by(&:first).transform_values { |v| v.map(&:last).uniq }
  end

  # line: { designation:, quantity:, unit: } → { candidates: [...], status: "chiffre"|"a_valider"|"a_demander" }
  def price(line)
    designation = line[:designation].to_s
    norm = SoumissionMatch.norm(designation)
    memory = SoumissionMatch.where(norm_designation: norm).to_a
    rejected = memory.select { |m| m.status == "rejected" }.map { |m| [ m.supplier_name, m.product_reference ] }
    learned = memory.select { |m| m.status == "confirmed" }.sort_by { |m| -m.uses }

    scored = []
    learned.each do |m|
      product = @products.find { |p| p.reference == m.product_reference && p.supplier.name == m.supplier_name }
      scored << [ product, 1.0, true ] if product
    end
    query = tokenize(designation)
    unless query.empty?
      @products.each do |p|
        next if rejected.include?([ p.supplier.name, p.reference ]) || scored.any? { |(sp, _, _)| sp.id == p.id }
        s = score(query, @tokens[p.id])
        scored << [ p, s, false ] if s >= MIN_SCORE
      end
    end
    top = scored.sort_by { |(p, s, l)| [ l ? 0 : 1, -s, @tokens[p.id].size ] }.first(MAX_CANDIDATES)
    candidates = top.map { |(p, s, l)| candidate(p, s, l, line) }
    { candidates: candidates, status: status_of(candidates) }
  end

  def self.normalize_unit(unit) = UNIT_ALIASES[unit.to_s.strip.downcase.delete(".")] || unit.to_s.strip.downcase

  private

  def status_of(candidates)
    return "a_demander" if candidates.empty?
    top = candidates.first
    top[:learned] || top[:score] >= 0.85 ? "chiffre" : "a_valider"
  end

  def candidate(product, score, learned, line)
    confidential = product.supplier.confidential_pricing
    price = confidential ? nil : product.unit_price.to_f
    qty = line[:quantity].presence&.to_f
    unit_ok = self.class.normalize_unit(line[:unit]) == self.class.normalize_unit(product.unite)
    { supplier: product.supplier.name, reference: product.reference, name: product.name, unite: product.unite,
      famille: product.famille, sousFamille: product.sous_famille, descriptif: product.descriptif.to_s.truncate(400),
      image: (product.image.to_s.start_with?("/", "http") ? product.image : nil), ficheUrl: product.fiche_url.presence, prix: price, confidential: confidential, score: score.round(2), learned: learned,
      unitMatch: unit_ok, total: (price && qty && unit_ok ? (price * qty).round(2) : nil) }
  end

  # Part pondérée des mots de la position retrouvés dans l'article (nombres/dimensions = poids double).
  def score(query, product_tokens)
    total = covered = 0.0
    text_hit = false
    query.each do |t|
      w = t.match?(/\d/) ? 2.0 : 1.0
      total += w
      hit = product_tokens.include?(t) || (@synonyms[t] || []).any? { |v| product_tokens.include?(v) }
      next unless hit
      covered += w
      text_hit = true unless t.match?(/\A\d+\z/)
    end
    text_hit && total.positive? ? covered / total : 0.0
  end

  def tokenize(text)
    SearchMemory.norm(text).split.reject { |w| w.length < 2 || STOPWORDS.include?(w) }
      .map { |w| w.length > 3 && w.end_with?("s") ? w.chomp("s") : w }.to_set
  end
end
