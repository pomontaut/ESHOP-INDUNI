# Indicateurs (écran Admin > « Indicateurs », administrateurs seulement) : construction de l'e-shop jour
# après jour (EshopMetric), commandes par jour et cumul, utilisation (agent d'usage, UsageReport).
class Api::IndicatorsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_admin

  def index
    from = (Date.iso8601(params[:from]) rescue nil) || EshopMetric::START_DATE
    zone = UsageReport::ZONE
    today = zone.today
    render json: { from: from.iso8601, today: today.iso8601,
                   build: EshopMetric.series(from), orders: orders_series(from, today, zone), usage: usage_series(from, today, zone) }
  end

  private

  def require_admin
    render json: { error: "Accès réservé aux administrateurs." }, status: :forbidden unless current_user&.admin?
  end

  # Commandes réellement créées dans l'outil (hors commandes d'essai « [TEST] »), par jour de création.
  def orders_series(from, today, zone)
    real = Order.where("sent_subject IS NULL OR sent_subject NOT LIKE ?", "[TEST]%")
    before = real.where("created_at < ?", zone.local(from.year, from.month, from.day)).count
    per_day = real.where("created_at >= ?", zone.local(from.year, from.month, from.day)).pluck(:created_at).map { |t| t.in_time_zone(zone).to_date }.tally
    cum = 0
    days = (from..today).map do |d|
      n = per_day[d].to_i
      cum += n
      { date: d.iso8601, count: n, cumulative: cum }
    end
    { before_period: before, total: before + cum, days: days }
  end

  def usage_series(from, today, zone)
    dates = UsageEvent.where("occurred_at >= ?", zone.local(from.year, from.month, from.day)).pluck(:occurred_at).map { |t| t.in_time_zone(zone).to_date }.uniq.sort.last(90)
    dates.map do |d|
      t = UsageReport.build(d)[:totals]
      { date: d.iso8601, users: t[:users_connected], tracked: t[:users_tracked], sessions: t[:sessions], active_seconds: t[:active_seconds],
        clicks: t[:clicks], searches: t[:searches], zero_results: t[:zero_results], adds: t[:adds],
        avg_seconds_to_cart: t[:avg_seconds_to_cart], avg_clicks_to_cart: t[:avg_clicks_to_cart], vias: t[:vias] }
    end
  end
end
