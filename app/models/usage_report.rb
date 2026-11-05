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
    orders = orders_between(from, to)
    per_user.each { |p| p[:orders] = orders.count { |o| o.user_id == p[:id] } }
    orders_untraced = untraced_orders(orders, per_user)

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
               top_queries: top_queries, zero_result_queries: zero, absent: absent,
               orders: orders.size, orders_untraced: orders_untraced }
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

  # ---------------------------------------------------------------- commandes (côté serveur)
  # Commandes réellement enregistrées par les utilisateurs suivis : source indépendante du navigateur,
  # pour repérer une commande que les mesures du navigateur n'ont pas vue (voir observations).
  def self.orders_between(from, to)
    tracked_ids = User.all.select(&:usage_tracked?).map(&:id)
    Order.where(created_at: from...to, user_id: tracked_ids).where.not("notes LIKE ?", "%[TEST]%").order(:created_at).to_a
  end

  # Commandes d'un utilisateur suivi sans aucun article ajouté au panier ce jour-là (ou sans aucune
  # mesure) : { name, number, supplier, at, reason }. Raisons possibles : mesure absente, panier préparé un
  # autre jour, import de devis / commande générique / reprise d'une commande (non vus avant ce correctif).
  def self.untraced_orders(orders, per_user)
    users = User.where(id: orders.map(&:user_id).uniq).index_by(&:id)
    orders.filter_map do |o|
      day = o.created_at.in_time_zone(ZONE).to_date
      stat = per_user.find { |p| p[:id] == o.user_id && (p[:date].nil? || p[:date] == day) }
      reason =
        if stat.nil? then "aucune mesure ce jour-là (onglet ouvert avant la mise à jour, navigateur bloquant les mesures, ou e-shop non rechargé)"
        elsif stat[:adds].zero? then "aucun ajout au panier mesuré (panier préparé un autre jour, import de devis, commande générique ou reprise d'une commande)"
        end
      next unless reason

      { name: users[o.user_id]&.full_name, number: o.number, supplier: o.supplier&.name,
        at: o.created_at.in_time_zone(ZONE).strftime("%H:%M"), reason: reason,
        searches: stat ? stat[:searches].map { |s| s[:q] }.first(8) : [] }
    end
  end

  # ---------------------------------------------------------- type de mot clef tapé
  KEYWORD_TYPES = {
    "reference"    => "Référence article (n° HGC, INDUNI…)",
    "dimension"    => "Dimension seule (DN100, 160x80, Ø110…)",
    "fournisseur"  => "Nom de fournisseur / marque",
    "mot_dimension" => "Désignation + dimension (ex. « tuyau 125 »)",
    "mot_seul"     => "Un seul mot (désignation)",
    "phrase"       => "Plusieurs mots (désignation)"
  }.freeze
  DIMENSION_RE = /\A(?:dn|ø|⌀|d)?\s*\d{2,4}(?:[.,]\d+)?(?:\s*(?:x|\*|×)\s*\d{1,4}(?:[.,]\d+)?)*\s*(?:mm|cm|m)?\z/i

  # refs : ensemble de références normalisées (sans espace, minuscules) des articles et n° INDUNI ; supplier_words :
  # mots des noms de fournisseurs. Heuristique [H] : aucun mot clef n'est inventé, seul le type est déduit de la forme.
  def self.keyword_type(query, refs = Set.new, supplier_words = Set.new)
    n = query.to_s.downcase.strip.gsub(/\s+/, " ")
    return nil if n.blank?

    compact = n.delete(" ")
    return "reference" if refs.include?(compact)
    return "dimension" if n.match?(DIMENSION_RE)
    return "reference" if n !~ /\s/ && n =~ /\d/ && n =~ /\A[a-z0-9][a-z0-9.\-\/_]*\z/ && (n.count("0-9") >= 5 || (n.count("0-9") >= 3 && n =~ /[a-z]/ && n !~ /\A(dn|d)?\d+(mm|cm|m)?\z/))

    words = n.split(" ")
    return "fournisseur" if words.all? { |w| supplier_words.include?(w) }
    return "mot_dimension" if words.size >= 2 && words.any? { |w| w.match?(DIMENSION_RE) }

    words.size == 1 ? "mot_seul" : "phrase"
  end

  def self.reference_set
    refs = Product.where.not(reference: [ nil, "" ]).pluck(:reference).map { |r| r.to_s.downcase.delete(" ") }
    refs += NomenclatureEntry.pluck(:induni_reference).map { |r| r.to_s.downcase.delete(" ") }
    refs.to_set
  end

  def self.supplier_word_set
    Supplier.pluck(:name).flat_map { |n| n.to_s.downcase.gsub(/[^a-z0-9àâéèêëîïôöûüç ]/, " ").split }.select { |w| w.size >= 3 }.to_set
  end

  def self.median(arr)
    a = arr.compact.sort
    return nil if a.empty?

    m = a.size / 2
    a.size.odd? ? a[m] : ((a[m - 1] + a[m]) / 2.0).round
  end

  # ------------------------------------------------------------ indicateurs sur une période
  # Indicateurs de recherche et de fréquentation sur `days` jours (jusqu'à `today`), lus sur les seuls
  # événements mesurés des utilisateurs suivis. Même méthode déterministe que le compte rendu quotidien.
  def self.indicators(days = 30, today = ZONE.today)
    days = days.to_i.clamp(1, 90)
    first = today - (days - 1)
    from = ZONE.local(first.year, first.month, first.day).beginning_of_day
    to   = ZONE.local(today.year, today.month, today.day).beginning_of_day + 1.day
    tracked = User.all.select(&:usage_tracked?).index_by(&:id)
    events = UsageEvent.where(occurred_at: from...to).order(:occurred_at, :id).to_a.select { |e| tracked.key?(e.user_id) }
    rows = events.group_by { |e| [ e.user_id, e.occurred_at.in_time_zone(ZONE).to_date ] }.filter_map do |(uid, date), evs|
      s = stats_for(tracked[uid], evs, from, to)
      s && s.merge(date: date)
    end
    working_days = (first..today).count { |d| working_day?(d) }

    # --- fréquentation par utilisateur
    per_user = tracked.values.sort_by { |u| u.full_name.to_s.downcase }.map do |u|
      r = rows.select { |x| x[:id] == u.id }
      active = r.sum { |x| x[:active_seconds] }
      sessions = r.sum { |x| x[:sessions] }
      { id: u.id, name: u.full_name, sector: u.sector, days_connected: r.size, sessions: sessions,
        active_seconds: active,
        avg_active_per_day: r.empty? ? nil : (active / r.size.to_f).round,
        avg_active_per_session: sessions.zero? ? nil : (active / sessions.to_f).round,
        sessions_per_day: r.empty? ? nil : (sessions / r.size.to_f).round(1),
        presence_pct: working_days.zero? ? nil : (100.0 * r.size / working_days).round,
        searches: r.sum { |x| x[:searches].size }, adds: r.sum { |x| x[:adds] },
        last_seen: r.map { |x| x[:date] }.max&.strftime("%d.%m.%Y") }
    end
    connected = per_user.select { |p| p[:days_connected].positive? }
    freq = { "Jamais" => 0, "1 jour" => 0, "2 à 4 jours" => 0, "5 à 9 jours" => 0, "10 jours et plus" => 0 }
    per_user.each do |p|
      k = case p[:days_connected] when 0 then "Jamais" when 1 then "1 jour" when 2..4 then "2 à 4 jours" when 5..9 then "5 à 9 jours" else "10 jours et plus" end
      freq[k] += 1
    end
    attendance = {
      users_tracked: per_user.size, users_connected: connected.size, working_days: working_days,
      avg_days_per_user: connected.empty? ? nil : (connected.sum { |p| p[:days_connected] } / connected.size.to_f).round(1),
      avg_sessions_per_user: connected.empty? ? nil : (connected.sum { |p| p[:sessions] } / connected.size.to_f).round(1),
      avg_active_per_user: connected.empty? ? nil : (connected.sum { |p| p[:active_seconds] } / connected.size.to_f).round,
      avg_active_per_user_day: rows.empty? ? nil : (rows.sum { |x| x[:active_seconds] } / rows.size.to_f).round,
      avg_active_per_session: rows.sum { |x| x[:sessions] }.zero? ? nil : (rows.sum { |x| x[:active_seconds] } / rows.sum { |x| x[:sessions] }.to_f).round,
      frequency: freq
    }
    by_day = (first..today).map do |d|
      r = rows.select { |x| x[:date] == d }
      { date: d.iso8601, users: r.size, active_seconds: r.sum { |x| x[:active_seconds] },
        avg_active: r.empty? ? nil : (r.sum { |x| x[:active_seconds] } / r.size.to_f).round,
        searches: r.sum { |x| x[:searches].size }, adds: r.sum { |x| x[:adds] }, working: working_day?(d) }
    end

    # --- recherche : mode, mots, délai avant panier
    refs = reference_set; sw = supplier_word_set
    searches = rows.flat_map { |x| x[:searches] }
    types = KEYWORD_TYPES.keys.index_with { |_| { n: 0, examples: Hash.new(0), zero: 0 } }
    searches.each do |s|
      t = keyword_type(s[:q], refs, sw) or next
      types[t][:n] += 1; types[t][:zero] += 1 if s[:results] == 0
      types[t][:examples][s[:q].to_s.downcase.strip] += 1
    end
    total_typed = types.values.sum { |v| v[:n] }
    keyword_types = KEYWORD_TYPES.map do |k, label|
      v = types[k]
      { key: k, label: label, n: v[:n], pct: total_typed.zero? ? 0 : (100.0 * v[:n] / total_typed).round, zero_results: v[:zero],
        examples: v[:examples].sort_by { |q, n| [ -n, q ] }.first(5).map { |q, n| [ q, n ] } }
    end
    clicks_via = rows.each_with_object(Hash.new(0)) { |x, h| x[:vias].each { |k, v| h[k] += v } }
    journeys = rows.flat_map { |x| x[:journeys] }
    carts = journeys.select { |j| j[:added] }
    adds_via = carts.group_by { |j| j[:via] || "inconnu" }.transform_values do |js|
      secs = js.filter_map { |j| j[:seconds] }
      { n: js.size, avg_seconds: secs.empty? ? nil : (secs.sum / secs.size.to_f).round, avg_clicks: (js.sum { |j| j[:clicks] } / js.size.to_f).round(1) }
    end
    searched = carts.select { |j| j[:queries].any? }
    secs = searched.filter_map { |j| j[:seconds] }
    buckets = { "< 30 s" => 0, "30 s – 1 min" => 0, "1 – 3 min" => 0, "3 – 5 min" => 0, "> 5 min" => 0 }
    secs.each do |s|
      k = s < 30 ? "< 30 s" : s < 60 ? "30 s – 1 min" : s < 180 ? "1 – 3 min" : s <= 300 ? "3 – 5 min" : "> 5 min"
      buckets[k] += 1
    end
    refs_to_cart = searched.count { |j| j[:queries].any? { |q| keyword_type(q, refs, sw) == "reference" } }
    time_to_cart = {
      carts: carts.size, carts_with_search: searched.size,
      avg_seconds: secs.empty? ? nil : (secs.sum / secs.size.to_f).round, median_seconds: median(secs),
      avg_queries: searched.empty? ? nil : (searched.sum { |j| j[:queries].size } / searched.size.to_f).round(1),
      avg_clicks: carts.empty? ? nil : (carts.sum { |j| j[:clicks] } / carts.size.to_f).round(1),
      by_reference: refs_to_cart, distribution: buckets,
      abandoned: journeys.count { |j| !j[:added] && j[:queries].any? }
    }

    # --- lien avec l'agent « moteur de recherche » : pistes de mots clefs / synonymes
    leads = Hash.new { |h, k| h[k] = { n: 0, targets: Hash.new(0), why: Set.new } }
    searches.each do |s|
      q = s[:q].to_s.downcase.strip
      next if q.blank? || s[:results] != 0

      leads[q][:n] += 1; leads[q][:why] << "sans résultat"
    end
    journeys.each do |j|
      next if j[:queries].empty?

      if j[:added] && j[:queries].size >= 3
        j[:queries].each { |q| l = leads[q.downcase.strip]; l[:n] += 1; l[:why] << "recherche difficile (3 requêtes ou plus avant l'ajout)"; l[:targets][j[:designation]] += 1 if j[:designation].present? }
      elsif !j[:added]
        j[:queries].last(1).each { |q| l = leads[q.downcase.strip]; l[:n] += 1; l[:why] << "abandon sans ajout" }
      end
    end
    keyword_leads = leads.sort_by { |q, v| [ -v[:n], q ] }.first(20).map do |q, v|
      { q: q, n: v[:n], why: v[:why].to_a, found_as: v[:targets].sort_by { |_, n| -n }.first(2).map(&:first) }
    end
    agent = { active: SearchMemory.active.count, pending: SearchMemory.where(status: "suggested").count }

    orders = orders_between(from, to)
    { from: first.iso8601, to: today.iso8601, days: days,
      generated_at: Time.current.in_time_zone(ZONE).strftime("%d.%m.%Y %H:%M"),
      attendance: attendance, users: per_user, by_day: by_day,
      search: { total: searches.size, zero_results: searches.count { |s| s[:results] == 0 }, clicks_via: clicks_via,
                adds_via: adds_via, keyword_types: keyword_types, time_to_cart: time_to_cart },
      keyword_leads: keyword_leads, search_agent: agent,
      orders: orders.size, orders_untraced: untraced_orders(orders, rows) }
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
    r[:orders_untraced].to_a.each do |o|
      obs << "⚠ #{o[:name]} : commande #{o[:number]} (#{o[:supplier]}, #{o[:at]}) envoyée sans parcours mesuré : #{o[:reason]}#{o[:searches].any? ? " — recherches vues : #{o[:searches].first(5).join(' › ')}" : ''}."
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
