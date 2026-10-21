# Reporting à la maille article des commandes e-shop : ce qu'on commande
# (quantités, montants, prix) et des indicateurs de bon fonctionnement du
# processus (annulations, e-mails, approbations, réceptions, catalogue).
#
# Utilisé par l'Analyse achat de l'e-shop (utilisateurs autorisés) et par
# l'export lu par SLA (fiche fournisseur) : mêmes chiffres dans les deux outils.
#
# Règles :
# - commandes annulées ou remplacées (ANNULE ET REMPLACE) : exclues des
#   totaux articles/montants, mais comptées dans les indicateurs de processus ;
# - commandes de test ("[TEST]" dans l'objet envoyé) : ignorées partout ;
# - fournisseur à prix confidentiel : quantités visibles, MAIS prix, montants
#   et écarts à nil sauf si `show_confidential` (jamais pour SLA).
class ArticleReport
  def initialize(scope:, from: nil, to: nil, supplier: nil, show_confidential: false)
    @scope = scope
    @from = parse_date(from)
    @to = parse_date(to)
    @supplier = supplier.presence
    @show_confidential = show_confidential
  end

  def as_json(*)
    {
      period: { from: @from&.iso8601, to: @to&.iso8601 },
      kpis: kpis,
      articles: articles,
      suppliers: suppliers,
      months: months,
      orders: orders
    }
  end

  private

  def parse_date(value)
    Date.parse(value.to_s) if value.present?
  rescue ArgumentError
    nil
  end

  def date_of(order) = (order.order_date || order.created_at.to_date)

  # Toutes les commandes de la période (hors test), annulées incluses.
  def all_orders
    @all_orders ||= begin
      rel = @scope.where.not("COALESCE(sent_subject, '') LIKE ?", "[TEST]%")
      rel = rel.joins(:supplier).where(suppliers: { name: @supplier }) if @supplier
      rel.includes(:supplier, :user, order_lines: :product).to_a
         .select { |o| (@from.nil? || date_of(o) >= @from) && (@to.nil? || date_of(o) <= @to) }
    end
  end

  def superseded_ids
    @superseded_ids ||= Order.where.not(modifies_order_id: nil).pluck(:modifies_order_id).to_set
  end

  def counted?(order) = !order.cancelled? && !superseded_ids.include?(order.id)

  def counted_orders = @counted_orders ||= all_orders.select { |o| counted?(o) }

  def masked?(supplier) = supplier&.confidential_pricing? && !@show_confidential

  def money(value, masked) = masked ? nil : value.to_f.round(2)

  def articles
    @articles ||= begin
      rows = Hash.new { |h, k| h[k] = { lines: [] } }
      counted_orders.sort_by { |o| [ date_of(o), o.id ] }.each do |o|
        o.order_lines.each do |l|
          next unless l.product
          rows[l.product][:lines] << [ o, l ]
        end
      end
      rows.map { |product, data| article_row(product, data[:lines]) }
          .sort_by { |r| -(r[:amount] || -1) }
    end
  end

  def article_row(product, lines)
    supplier = product.supplier
    masked = masked?(supplier)
    qty = lines.sum { |_, l| l.quantity.to_i }
    amount = lines.sum { |_, l| l.subtotal }
    prices = lines.map { |_, l| l.unit_price.to_f }.reject(&:zero?)
    gain = lines.sum { |_, l| l.catalog_price ? (l.catalog_price.to_f - l.unit_price.to_f) * l.quantity.to_i : 0 }
    variation = prices.size > 1 && prices.first.positive? ? ((prices.last - prices.first) / prices.first * 100).round(1) : nil
    {
      supplier: supplier&.name, reference: product.reference, name: product.name,
      famille: product.famille, unite: product.unite, equivalenceKey: product.equivalence_key,
      qty: qty, nbOrders: lines.map { |o, _| o.id }.uniq.size,
      amount: money(amount, masked),
      avgPrice: masked || qty.zero? ? nil : (amount / qty).round(2),
      lastPrice: masked ? nil : prices.last&.round(2),
      catalogPrice: masked ? nil : product.unit_price&.to_f&.round(2),
      priceVariationPct: masked ? nil : variation,
      gain: masked ? nil : gain.round(2),
      confidential: supplier&.confidential_pricing? || false
    }
  end

  def suppliers
    articles.group_by { |a| a[:supplier] }.map do |name, rows|
      {
        name: name, nbArticles: rows.size, qty: rows.sum { |r| r[:qty] },
        nbOrders: counted_orders.count { |o| o.supplier&.name == name },
        amount: rows.any? { |r| r[:amount].nil? } ? nil : rows.sum { |r| r[:amount] }.round(2),
        confidential: rows.any? { |r| r[:confidential] }
      }
    end.sort_by { |s| -(s[:amount] || -1) }
  end

  def months
    counted_orders.group_by { |o| date_of(o).strftime("%Y-%m") }.sort.map do |month, os|
      visible = os.reject { |o| masked?(o.supplier) }
      { month: month, nbOrders: os.size, amount: visible.sum { |o| o.total.to_f }.round(2),
        users: os.filter_map(&:user_id).uniq.size }
    end
  end

  def orders
    counted_orders.sort_by { |o| [ date_of(o), o.id ] }.reverse.map do |o|
      masked = masked?(o.supplier)
      {
        no: o.number, date: date_of(o).iso8601, supplier: o.supplier&.name,
        chantier: o.chantier_name, status: o.approval_status.presence || o.status,
        total: money(o.total, masked),
        extraCharges: masked ? nil : o.extra_charges_total.round(2),
        confidential: o.supplier&.confidential_pricing? || false,
        items: o.order_lines.map { |l|
          { article: l.product&.reference, designation: l.product&.name, unite: l.product&.unite,
            qty: l.quantity.to_i, unitPrice: money(l.unit_price, masked), amount: money(l.subtotal, masked) }
        }
      }
    end
  end

  # Indicateurs « l'e-shop fonctionne-t-il bien ? »
  def kpis
    all = all_orders
    sent = all.reject(&:cancelled?)
    ordered_product_ids = counted_orders.flat_map { |o| o.order_lines.map(&:product_id) }.to_set
    catalog = Product.where.not(famille: nil)
    catalog = catalog.joins(:supplier).where(suppliers: { name: @supplier }) if @supplier
    catalog_ids = catalog.pluck(:id)
    gain_rows = articles.reject { |a| a[:gain].nil? }
    {
      nbOrders: counted_orders.size,
      nbOrdersAll: all.size,
      nbCancelled: all.count(&:cancelled?),
      nbSuperseded: all.count { |o| !o.cancelled? && superseded_ids.include?(o.id) },
      nbEmailNotSent: sent.count { |o| o.email_sent_at.nil? && !o.pending_approval? && !o.refused? },
      nbPendingApproval: all.count(&:pending_approval?),
      nbRefused: all.count(&:refused?),
      nbRelanced: all.count { |o| o.relance_sent_at.present? },
      nbReceptionConfirmed: counted_orders.count(&:reception_confirmed?),
      nbInvoiced: counted_orders.count { |o| o.invoiced_at.present? },
      nbActiveUsers: counted_orders.filter_map(&:user_id).uniq.size,
      nbChantiers: counted_orders.filter_map(&:chantier_name).uniq.size,
      nbArticlesOrdered: articles.size,
      nbCatalogArticles: catalog_ids.size,
      nbCatalogNeverOrdered: catalog_ids.count { |id| !ordered_product_ids.include?(id) },
      gainVsCatalog: gain_rows.sum { |a| a[:gain] }.round(2),
      nbPricesChanged: articles.count { |a| a[:priceVariationPct].to_f.nonzero? }
    }
  end
end
