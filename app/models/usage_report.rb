# Agent d'usage de l'e-shop (administrateur seulement) : compte rendu quotidien du comportement des
# utilisateurs suivis (hors administrateurs et service achats, voir User#usage_tracked?) :
# connexions, temps actif, clics, recherches (mots tapés, premiers mots), parcours jusqu'à
# l'ajout au panier (durée, clics, moyen de recherche), difficultés repérées. Méthode déterministe,
# sans modèle ; aucune donnée de prix. Voir docs/agents/agent_usage_eshop.md.
class UsageReport < ApplicationRecord
  ZONE = ActiveSupport::TimeZone["Europe/Zurich"]
  SEND_AFTER_HOUR = 16 # heure de Zurich ; envoi à 16h00 les jours ouvrés genevois où il y a eu de l'activité
  SEND_AFTER_MINUTE = 0
  LONG_JOURNEY_SECONDS = 300 # [H] parcours jugé long au-delà de 5 min
  LONG_JOURNEY_CLICKS = 15   # [H] ou de 15 clics
  RETENTION_DAYS = 90

  serialize :summary, coder: JSON

  # ------------------------------------------------------------------ calcul
  def self.build(date)
    date = date.to_date
    from = ZONE.local(date.year, date.month, date.day).beginning_of_day
    to   = from + 1.day
    events = UsageEvent.where(occurred_at: from...to).order(:occurred_at, :id).to_a
    users  = User.where(id: events.map(&:user_id).uniq).select(&:usage_tracked?).index_by(&:id)
    events.select! { |e| users.key?(e.user_id) }

    per_user = users.values.sort_by { |u| u.full_name.to_s.downcase }.filter_map do |u|
      stats_for(u, events.select { |e| e.user_id == u.id }, from, to)
    end

    tracked = User.all.select(&:usage_tracked?)
    seen_ids = per_user.map { |p| p[:id] }
    last_seen = UsageSession.where(user_id: tracked.map(&:id)).group(:user_id).maximum(:last_seen_at)
    absent = tracked.reject { |u| seen_ids.include?(u.id) }.map { |u|
      { name: u.full_name, sector: u.sector, last_seen: last_seen[u.id]&.in_time_zone(ZONE)&.strftime("%d.%m.%Y") }
    }.sort_by { |a| a[:name].to_s.downcase }

    queries = per_user.flat_map { |p| p[:searches] }
    top_queries = queries.map { |s| s[:q].to_s.downcase.strip }.reject(&:blank?).tally.sort_by { |q, n| [ -n, q ] }.first(15)
    zero = queries.select { |s| s[:results] == 0 }.map { |s| s[:q].to_s.downcase.strip }.tally.sort_by { |q, n| [ -n, q ] }.first(15)

    totals = {
      users_connected: per_user.size, users_tracked: tracked.size,
      sessions:        per_user.sum { |p| p[:sessions] },
      logins:          per_user.sum { |p| p[:logins] },
      active_seconds:  per_user.sum { |p| p[:active_seconds] },
      clicks:          per_user.sum { |p| p[:clicks] },
      searches:        per_user.sum { |p| p[:searches].size },
      adds:            per_user.sum { |p| p[:adds] },
      zero_results:    per_user.sum { |p| p[:zero_results] }
    }
    carts = per_user.flat_map { |p| p[:journeys].select { |j| j[:added] } }
    totals[:avg_seconds_to_cart] = carts.empty? ? nil : (carts.sum { |j| j[:seconds] } / carts.size.to_f).round
    totals[:avg_clicks_to_cart]  = carts.empty? ? nil : (carts.sum { |j| j[:clicks] } / carts.size.to_f).round(1)
    totals[:vias] = per_user.each_with_object(Hash.new(0)) { |p, h| p[:vias].each { |k, v| h[k] += v } }

    report = { date: date.iso8601, generated_at: Time.current.in_time_zone(ZONE).strftime("%d.%m.%Y %H:%M"),
               totals: totals, users: per_user.map { |p| p.except(:searches_raw) },
               top_queries: top_queries, zero_result_queries: zero, absent: absent }
    report[:observations] = observations(report)
    report
  end

  def self.stats_for(user, evs, from, to)
    sessions = evs.group_by(&:usage_session_id)
    session_rows = UsageSession.where(id: sessions.keys.compact).index_by(&:id)
    journeys = []; searches = []; vias = Hash.new(0); first_queries = []
    sessions.each do |sid, list|
      cur = nil
      list.each do |e|
        d = e.payload
        case e.kind
        when "click"
          cur ||= { start: e.occurred_at, clicks: 0, queries: [], navs: 0 }
          cur[:clicks] += 1
          vias[d["via"]] += 1 if UsageEvent::VIAS.include?(d["via"])
        when "nav"
          cur ||= { start: e.occurred_at, clicks: 0, queries: [], navs: 0 }
          cur[:navs] += 1
        when "search"
          cur ||= { start: e.occurred_at, clicks: 0, queries: [], navs: 0 }
          q = d["q"].to_s.strip
          next if q.blank?
          cur[:queries] << q
          searches << { q: q, results: d["results"], at: e.occurred_at.in_time_zone(ZONE).strftime("%H:%M") }
        when "add_to_cart"
          cur ||= { start: e.occurred_at, clicks: 0, queries: [], navs: 0 }
          journeys << finish(cur, e.occurred_at, d)
          cur = nil
        end
      end
      journeys << finish(cur, nil, nil) if cur && (cur[:clicks] + cur[:queries].size + cur[:navs]).positive?
    end
    return nil if sessions.empty?

    srows = session_rows.values
    first_queries = journeys.filter_map { |j| j[:queries].first }.first(8)
    carts = journeys.select { |j| j[:added] }
    {
      id: user.id, name: user.full_name, sector: user.sector, job_function: user.job_function,
      logins:         evs.count { |e| e.kind == "login" },
      sessions:       srows.size.nonzero? || sessions.keys.compact.size,
      active_seconds: srows.sum(&:active_seconds),
      span_seconds:   srows.sum { |s| (s.last_seen_at - s.started_at).to_i },
      first_seen:     evs.first.occurred_at.in_time_zone(ZONE).strftime("%H:%M"),
      last_seen:      evs.last.occurred_at.in_time_zone(ZONE).strftime("%H:%M"),
      clicks:         [ srows.sum(&:clicks), evs.count { |e| e.kind == "click" } ].max,
      searches:       searches,
      zero_results:   searches.count { |s| s[:results] == 0 },
      adds:           carts.size,
      avg_seconds_to_cart: carts.empty? ? nil : (carts.sum { |j| j[:seconds] } / carts.size.to_f).round,
      avg_clicks_to_cart:  carts.empty? ? nil : (carts.sum { |j| j[:clicks] } / carts.size.to_f).round(1),
      vias:           vias,
      first_queries:  first_queries,
      journeys:       journeys.first(40)
    }
  end

  def self.finish(cur, stop, add)
    {
      added: !add.nil?, seconds: stop ? (stop - cur[:start]).round : nil, clicks: cur[:clicks], navs: cur[:navs],
      queries: cur[:queries], via: add && add["via"], article: add && add["article"], catalog: add && add["catalog"],
      designation: add && add["designation"], at: cur[:start].in_time_zone(ZONE).strftime("%H:%M")
    }
  end

  # Observations factuelles (règles fixes) ; rien n'est inventé : seules les mesures du jour sont lues.
  def self.observations(r)
    obs = []
    r[:users].each do |u|
      if u[:adds].zero?
        obs << "#{u[:name]} : connecté #{u[:sessions]} fois (#{(u[:active_seconds] / 60.0).round} min actives), #{u[:searches].size} recherche(s), #{u[:clicks]} clic(s), aucun article ajouté au panier."
      end
      u[:journeys].select { |j| j[:added] && (j[:seconds].to_i > LONG_JOURNEY_SECONDS || j[:clicks] > LONG_JOURNEY_CLICKS) }.each do |j|
        obs << "#{u[:name]} : parcours long jusqu'au panier (#{(j[:seconds].to_i / 60.0).round(1)} min, #{j[:clicks]} clics#{j[:queries].any? ? ", recherches : #{j[:queries].first(4).join(' › ')}" : ''}) → « #{j[:designation]} »."
      end
      obs << "#{u[:name]} : #{u[:zero_results]} recherche(s) sans résultat." if u[:zero_results] >= 2
    end
    r[:zero_result_queries].each { |q, n| obs << "Recherche sans résultat « #{q} » (#{n}×) : mot clef ou synonyme à ajouter." }
    if r[:absent].any? && r[:totals][:users_connected].positive?
      obs << "#{r[:absent].size} utilisateur(s) suivi(s) ne se sont pas connectés ce jour."
    end
    obs << "Aucune activité enregistrée ce jour." if r[:totals][:users_connected].zero?
    obs
  end

  # ------------------------------------------------------------ envoi quotidien
  # Jours fériés officiels du canton de Genève : 1er janvier, Vendredi saint, lundi de Pâques,
  # Ascension, lundi de Pentecôte, 1er août, Jeûne genevois (jeudi après le 1er dimanche de
  # septembre), Noël, 31 décembre (Restauration de la République).
  def self.geneva_holidays(year)
    a = year % 19
    b, c = year.divmod(100)
    d, e = b.divmod(4)
    g = (8 * b + 13) / 25
    h = (19 * a + b - d - g + 15) % 30
    i, k = c.divmod(4)
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 19 * l) / 433
    n = h + l - 7 * m + 114
    easter = Date.new(year, n / 31, n % 31 + 1)
    sept1 = Date.new(year, 9, 1)
    first_sunday = sept1 + ((7 - sept1.wday) % 7)
    [ Date.new(year, 1, 1), easter - 2, easter + 1, easter + 39, easter + 50, Date.new(year, 8, 1),
      first_sunday + 4, Date.new(year, 12, 25), Date.new(year, 12, 31) ]
  end

  def self.working_day?(date)
    !(date.saturday? || date.sunday? || geneva_holidays(date.year).include?(date))
  end

  # Appelé périodiquement (config/puma.rb) : à partir de 16h00 (Zurich), les jours ouvrés (hors week-end
  # et jours fériés genevois), génère, archive et envoie le compte rendu du jour une seule fois,
  # seulement s'il y a eu de l'activité. Désactivable avec USAGE_REPORT_AUTO=false.
  def self.run_due!(now = Time.current)
    local = now.in_time_zone(ZONE)
    return unless working_day?(local.to_date)
    return unless local.hour > SEND_AFTER_HOUR || (local.hour == SEND_AFTER_HOUR && local.min >= SEND_AFTER_MINUTE)

    date = local.to_date
    return if where(report_date: date).where.not(emailed_at: nil).exists?

    send_report!(date)
  end

  def self.send_report!(date)
    summary = build(date)
    row = find_or_initialize_by(report_date: date)
    row.summary = summary
    recipients = User::PERMANENT_ADMIN_EMAILS
    if summary[:totals][:users_connected].zero?
      row.emailed_at = Time.current # pas d'e-mail les jours sans activité
    else
      recipients.each { |to| UsageMailer.daily_report(to, summary).deliver_now }
      row.emailed_at = Time.current
    end
    row.save!
    purge_old!
    summary
  end

  def self.purge_old!
    limit = RETENTION_DAYS.days.ago
    UsageEvent.where("occurred_at < ?", limit).delete_all
    UsageSession.where("last_seen_at < ?", limit).delete_all
  end
end
