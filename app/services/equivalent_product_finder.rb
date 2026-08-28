# Finds, for a devis line's designation, the closest known equivalent
# article already in our catalog (any supplier) — so an import de devis can
# tell the buyer whether we already have that same kind of article cheaper
# elsewhere before they accept the supplier's quoted price.
class EquivalentProductFinder
  STOPWORDS = %w[de le la les du des en et ou pour avec sans par au aux d l un une].freeze
  MIN_SCORE = 0.5

  def initialize(scope = default_scope)
    @products = scope.to_a
    @tokens_by_product_id = @products.index_with { |p| tokenize(p.name) }
  end

  # Returns the Product (from another reference than `exclude`) whose name
  # best overlaps `designation`, or nil if nothing crosses the similarity
  # threshold. Confidential-pricing suppliers (ex. Sika) are never
  # candidates : their net price must never leave the Analyse achat module.
  def find(designation, exclude: nil)
    query_tokens = tokenize(designation)
    return nil if query_tokens.empty?

    best = nil
    best_score = 0.0
    @products.each do |product|
      next if exclude && product.id == exclude.id
      score = overlap(query_tokens, @tokens_by_product_id[product])
      next if score <= best_score
      best_score = score
      best = product
    end
    best_score >= MIN_SCORE ? best : nil
  end

  private

  def default_scope
    Product.joins(:supplier)
      .where.not(famille: nil)
      .where(suppliers: { confidential_pricing: false })
      .where("products.unit_price > 0")
      .includes(:supplier)
  end

  def tokenize(text)
    text.to_s.downcase
      .unicode_normalize(:nfkd).encode("ASCII", invalid: :replace, undef: :replace, replace: "")
      .scan(/[a-z0-9]+/)
      .reject { |w| w.length < 3 || STOPWORDS.include?(w) }
      .to_set
  end

  def overlap(a, b)
    return 0.0 if a.empty? || b.empty?
    (a & b).size.to_f / [ a.size, b.size ].min
  end
end
