# Suivi automatique d'une commande : Commandé / Planifié / Livré / Accepté /
# Restant / Facturé. Ne manipule que des quantités (jamais de prix : les prix
# confidentiels ne doivent pas sortir du module Analyse achat).
class OrderReceptionTracker
  TYPES = {
    "C1" => { label: "C1 – Diffus", hint: "Inférieure à 5'000 CHF, via catalogue : commande simple, réception simplifiée" },
    "C2" => { label: "C2 – Livraison unique", hint: "Supérieure à 5'000 CHF, une livraison : commande + réception unique" },
    "C3" => { label: "C3 – Multijours", hint: "Supérieure à 5'000 CHF, livraisons échelonnées : commande + appels de livraison + réceptions" },
    "C4" => { label: "C4 – Multirotations", hint: "Tous montants, plusieurs livraisons dans une journée : commande + programme journalier + réceptions par rotation" },
    "C5" => { label: "C5 – Prestation / sous-traitance", hint: "Réception par avancement, attachement ou validation de service, plutôt que par livraison physique" }
  }.freeze
  THRESHOLD = 5000

  STATUS_LABELS = {
    "ordered" => "Commandé", "planned" => "Planifié", "partial" => "Livré partiellement",
    "delivered" => "Livré (à valider)", "accepted" => "Accepté / soldé", "invoiced" => "Facturé"
  }.freeze

  def self.suggested_type(order)
    return "C2" if order.supplier&.confidential_pricing?

    order.total.to_f < THRESHOLD ? "C1" : "C2"
  end

  def initialize(order)
    @order = order
    @receptions = order.receptions.to_a
    @calls = order.delivery_calls.to_a
  end

  def type = @order.reception_type.presence || self.class.suggested_type(@order)
  def service? = type == "C5"

  def line_rows
    planned = Hash.new(0.to_d)
    @calls.select(&:open?).each { |c| c.lines.each { |l| planned[l.order_line_id] += l.quantity.to_d } }
    delivered = Hash.new(0.to_d)
    accepted = Hash.new(0.to_d)
    @receptions.each do |r|
      r.lines.each do |l|
        delivered[l.order_line_id] += l.quantity_received.to_d
        accepted[l.order_line_id] += l.quantity_accepted.to_d
      end
    end
    @order.order_lines.sort_by(&:id).map do |l|
      ordered = l.quantity.to_d
      remaining = [ ordered - accepted[l.id], 0.to_d ].max
      {
        id: l.id, article: l.product&.reference, designation: l.product&.name, unit: l.product&.unite,
        ordered: ordered.to_f, planned: [ planned[l.id], 0 ].max.to_f, delivered: delivered[l.id].to_f,
        accepted: accepted[l.id].to_f, remaining: remaining.to_f,
        unplanned: [ ordered - accepted[l.id] - planned[l.id], 0.to_d ].max.to_f
      }
    end
  end

  # Avancement accepté, en % : prestations = dernier avancement validé ; sinon
  # quantités acceptées / commandées (plafonnées par ligne).
  def accepted_percent
    if service?
      @receptions.reject { |r| r.status == "refuse" }.filter_map(&:progress_percent).max.to_f
    else
      rows = line_rows
      total = rows.sum { |r| r[:ordered] }
      return 0.0 if total.zero?

      (rows.sum { |r| [ r[:accepted], r[:ordered] ].min } / total * 100).round(1)
    end
  end

  def status
    return "invoiced" if @order.invoiced_at.present?
    return "accepted" if accepted_percent >= 100

    if @receptions.any?
      fully_delivered = !service? && line_rows.all? { |r| r[:delivered] >= r[:ordered] }
      return fully_delivered ? "delivered" : "partial"
    end
    return "planned" if @calls.any?(&:open?)

    "ordered"
  end

  def next_call
    @calls.select(&:open?).min_by { |c| [ c.planned_on, c.planned_time.to_s ] }
  end

  def summary
    {
      type: type, typeSuggested: @order.reception_type.blank?, status: status, statusLabel: STATUS_LABELS[status],
      acceptedPercent: accepted_percent, nextDelivery: next_call&.planned_on&.strftime("%d.%m.%Y"),
      nextDeliveryTime: next_call&.planned_time, receptions: @receptions.size,
      scans: @receptions.sum { |r| r.scans.size }, openCalls: @calls.count(&:open?)
    }
  end
end
