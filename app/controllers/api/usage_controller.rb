# Agent d'usage de l'e-shop. `events` : réception des mesures du navigateur (utilisateurs suivis
# seulement, voir User#usage_tracked?) ; `report` / `send_report` : administrateurs seulement.
class Api::UsageController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_admin, only: %i[report send_report]

  MAX_EVENTS_PER_BATCH = 200
  MAX_EVENTS_PER_SESSION = 3000

  def events
    return head :no_content unless current_user&.usage_tracked?

    token = params[:session].to_s[0, 64]
    return head :unprocessable_entity if token.blank?

    now = Time.current
    sess = UsageSession.find_or_initialize_by(token: token)
    return head :forbidden if sess.persisted? && sess.user_id != current_user.id

    sess.assign_attributes(user_id: current_user.id, started_at: sess.started_at || now, last_seen_at: now,
                           user_agent: request.user_agent.to_s[0, 160])
    sess.active_seconds = [ sess.active_seconds, params[:active_seconds].to_i.clamp(0, 86_400) ].max
    sess.clicks         = [ sess.clicks, params[:clicks].to_i.clamp(0, 100_000) ].max
    sess.save!

    room = MAX_EVENTS_PER_SESSION - sess.usage_events.count
    Array(params[:events]).first([ MAX_EVENTS_PER_BATCH, [ room, 0 ].max ].min).each do |ev|
      kind = ev[:k].to_s
      next unless UsageEvent::KINDS.include?(kind) && kind != "login"

      sess.usage_events.create!(user_id: current_user.id, kind: kind, occurred_at: event_time(ev[:t], now),
                                data: sanitize(ev[:d]).to_json)
    end
    head :no_content
  end

  def report
    date = params[:date].present? ? (Date.iso8601(params[:date]) rescue nil) : UsageReport::ZONE.today
    return render(json: { error: "Date invalide." }, status: :unprocessable_entity) unless date

    render json: UsageReport.build(date)
  end

  # Génère et envoie le compte rendu du jour par e-mail à l'administrateur (propriétaire).
  def send_report
    date = params[:date].present? ? (Date.iso8601(params[:date]) rescue nil) : UsageReport::ZONE.today
    return render(json: { error: "Date invalide." }, status: :unprocessable_entity) unless date

    report = UsageReport.send_report!(date)
    render json: { sent: report[:totals][:users_connected].positive?, recipients: User::PERMANENT_ADMIN_EMAILS }
  end

  private

  def require_admin
    render json: { error: "Accès réservé aux administrateurs." }, status: :forbidden unless current_user&.admin?
  end

  def event_time(ms, now)
    t = ms.to_i.positive? ? Time.at(ms.to_i / 1000.0) : now
    (t - now).abs > 1.day ? now : t
  end

  # Texte court, aucune donnée sensible : article, fournisseur, mots tapés, moyen de recherche.
  def sanitize(d)
    h = d.respond_to?(:to_unsafe_h) ? d.to_unsafe_h : {}
    out = {}
    %w[q via view catalog famille sous article designation text].each { |k| out[k] = h[k].to_s.strip[0, 120] if h[k].present? }
    out["via"] = nil unless UsageEvent::VIAS.include?(out["via"])
    out.delete("via") if out["via"].nil?
    out["results"] = h["results"].to_i.clamp(0, 100_000) if h.key?("results")
    out
  end
end
