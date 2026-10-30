# Agent « moteur de recherche » (bandeau de recherche) — chat réservé aux administrateurs.
# Méthode déterministe (commandes en français, aucun appel à un modèle) :
# - mémorise des synonymes et des mots clefs supplémentaires par article (SearchMemory), appliqués
#   immédiatement à tous les utilisateurs ;
# - lit les retours de l'agent d'usage (UsageReport) : recherches sans résultat, nombre de requêtes et
#   temps avant l'ajout au panier, moyen utilisé ; propose des mots clefs d'après les parcours réels
#   (ce que l'utilisateur a tapé → l'article qu'il a finalement mis au panier).
# Voir docs/agents/agent_moteur_recherche.md.
class SearchAgent
  Result = Struct.new(:reply, :changed, :updates, :synonyms, keyword_init: true)

  HELP = <<~TXT.freeze
    Je gère la mémoire du moteur de recherche. Exemples :
    • « ajoute les mots clefs culotte, raccord en Y pour 381100018 » (n° INDUNI, référence fournisseur ou nom de l'article)
    • « synonyme : culotte = embranchement, raccord en Y » (dans les deux sens)
    • « quand on tape siphon de cour, il faut trouver 100006411 » (un seul sens)
    • « teste tuyau drainage 125 » (essaie le vrai moteur et montre les 5 premiers résultats)
    • « règle : pénalise drainage sauf si on tape drain » · « règle : favorise sn4 quand on tape sn4 » (règles de classement)
    • « pourquoi quand je tape … je tombe sur … ? » (explique le classement avec le vrai moteur)
    • « bilan » (qualité de la recherche d'après l'agent d'usage, 7 jours) · « suggestions » puis « valide 12 13 », « valide tout » ou « ignore 14 »
    • « mémoire » (ce que j'ai appris) · « oublie 12 » ou « oublie culotte »
    Tout ce que je mémorise s'applique tout de suite pour tous les utilisateurs.
  TXT

  def initialize(user)
    @user = user
  end

  # `engine` : mesures du vrai moteur faites dans le navigateur de l'administrateur pour les requêtes citées
  # dans son message (classement, détail par article) — voir srchEngineContext dans catalogue.html.
  def reply(text, engine: nil)
    @engine = engine
    note = nil
    if Brain.available?
      begin
        return Brain.new(self, @user).run(text, engine)
      rescue StandardError => e
        Rails.logger.error("[search_agent] #{e.class}: #{e.message}")
        note = "⚠️ La compréhension du français libre est indisponible pour le moment (#{e.class} : #{e.message.to_s.squish[0, 300]}) : j'applique seulement les commandes simples.\n\n"
      end
    else
      note = :no_key
    end
    res = reply_by_rules(text)
    if note == :no_key && res.reply.start_with?("Je n'ai pas compris")
      res.reply = "Je n'ai pas compris cette formulation : la compréhension du français libre demande la clé ANTHROPIC_API_KEY sur le serveur (elle n'est pas configurée). En attendant, voici les commandes que je sais exécuter.\n\n#{HELP}"
    elsif note.is_a?(String)
      res.reply = note + res.reply
    end
    res
  end

  def reply_by_rules(text)
    s = text.to_s.strip.sub(/[.!]+\z/, "")
    return result(HELP) if s.blank? || s =~ /\A(aide|help|\?|commandes?|que sais-tu faire)\z/i
    return explain_engine if @engine.present? && s =~ /pourquoi|explique|comment se fait|comprends pas|devrait|au lieu de|et non/i

    case s
    when /\A(?:oublie|supprime|retire|efface)\s+(.+)\z/i then forget(Regexp.last_match(1))
    when /\A(?:valide|accepte|applique)\s+(.+)\z/i       then decide(Regexp.last_match(1), "active")
    when /\A(?:ignore|refuse|rejette)\s+(.+)\z/i         then decide(Regexp.last_match(1), "ignored")
    when /\A(?:suggestions?|propositions?|apprends?|que me proposes-tu)\b/i then suggestions
    when /\A(?:bilan|analyse|retours?|diagnostic|qualit[eé]|difficult[eé]s?|recherches? sans r[eé]sultats?|stats?)\b/i then insights
    when /\A(?:m[eé]moire|que sais-tu|liste)\b/i         then list_memory
    when /\Asynonymes?\s*:?\s*(.+)\z/i                  then add_synonym(Regexp.last_match(1))
    when /\Ar[eè]gle\s*:?\s*(?:p[eé]nalise|descends?|recule|rel[eè]gue)\s+(.+?)\s+sauf\s+si\s+(?:on tape|la requ[eê]te (?:contient|parle de))\s+(.+?)(?:\s*\(?([+-]?\d+)\)?)?\z/i
      add_rule_from(Regexp.last_match(1), Regexp.last_match(2), -(Regexp.last_match(3) || 120).to_i.abs, nil)
    when /\Ar[eè]gle\s*:?\s*(?:monte|favorise|remonte)\s+(.+?)\s+quand\s+(?:on tape|la requ[eê]te contient)\s+(.+?)(?:\s*\(?([+-]?\d+)\)?)?\z/i
      add_rule_from(Regexp.last_match(1), nil, (Regexp.last_match(3) || 120).to_i.abs, Regexp.last_match(2))
    when /(?:quand|si)\s+(?:on|un utilisateur|l'utilisateur|les gens|ils)?\s*(?:tape|saisit|cherche|recherche)\w*\s+(.+?)\s*[,;]?\s*(?:alors\s+)?(?:il faut\s+|on doit\s+|doit\s+|faut\s+)?(?:trouver|proposer|afficher|retourner|renvoyer)\s+(.+)\z/i
      when_typing(Regexp.last_match(1), Regexp.last_match(2))
    when /\A(?:ajoute|rajoute|m[eé]morise|retiens)\s+(?:les |le |la |ces |ce )?(?:mots?\s*cl[eé]f?s?|mots?|termes?|expressions?)?\s*:?\s*(.+)\z/i,
         /\Amots?\s*cl[eé]f?s?\s*:?\s*(.+)\z/i
      add_keywords(Regexp.last_match(1))
    else
      result("Je n'ai pas compris, mais votre retour est enregistré dans l'historique.\n\n#{HELP}")
    end
  end

  # ------------------------------------------------------------------ mémoire
  def add_synonym(rest)
    left, right = rest.split(/\s*(?:=>|->|<->|↔|=|équivaut à|equivaut a|comme)\s*/i, 2)
    values = SearchMemory.split_list(right)
    term = clean_term(left)
    return result("Format : « synonyme : culotte = embranchement, raccord en Y ».") if term.blank? || values.empty?

    save_synonym(term, values, one_way: false)
  end

  def when_typing(typed, wanted)
    term = clean_term(typed)
    cands = candidates(wanted)
    if cands.size == 1
      add_keyword_rows([ term ], cands.first)
    elsif cands.empty?
      save_synonym(term, SearchMemory.split_list(wanted.sub(/\A(?:les?|la|des|un|une)\s+/i, "")), one_way: true)
    else
      ambiguous(cands)
    end
  end

  def add_keywords(rest)
    pivot = /\s+(?:pour|sur|dans|à|a)\s+(?:l'article\s+|les?\s+articles?\s+|le\s+n°\s*|la\s+référence\s+)?/i
    positions = rest.to_enum(:scan, pivot).map { Regexp.last_match.begin(0) }
    return result("Précisez l'article : « ajoute les mots clefs culotte, raccord en Y pour 381100018 ».") if positions.empty?

    positions.reverse_each do |pos|
      m = rest[pos..].match(pivot)
      words = SearchMemory.split_list(rest[0...pos])
      target_text = rest[(pos + m[0].length)..].to_s.strip
      next if words.empty? || target_text.blank?

      cands = candidates(target_text)
      next if cands.empty?
      return cands.size == 1 ? add_keyword_rows(words, cands.first) : ambiguous(cands)
    end
    result("Je n'ai trouvé aucun article correspondant. Donnez le n° INDUNI, la référence fournisseur ou une partie plus précise du nom.")
  end

  def forget(what)
    w = what.strip.sub(/\A(?:le |la |les |l')?(?:mot\s*cl[eé]s?\s*|synonyme\s*)?/i, "")
    ids = w.scan(/#?(\d+)/).flatten.map(&:to_i) if w =~ /\A[#\d\s,et]+\z/
    rows = if ids&.any? then SearchMemory.where(id: ids)
           elsif w =~ /\A(?:tout|toute la m[eé]moire)\z/i then SearchMemory.where(status: "active")
           else SearchMemory.all.select { |m| SearchMemory.norm(m.term) == SearchMemory.norm(w) || SearchMemory.split_list(m.value).any? { |v| SearchMemory.norm(v) == SearchMemory.norm(w) } }
           end
    rows = SearchMemory.where(id: rows.map(&:id)) unless rows.is_a?(ActiveRecord::Relation)
    return result("Rien à oublier pour « #{w} ».") if rows.empty?

    labels = rows.map { |m| describe(m) }
    keys = target_keys(rows.to_a)
    rows.destroy_all
    result("J'ai oublié :\n#{labels.join("\n")}", changed: true, updates: build_updates(keys), synonyms: true)
  end

  def list_memory
    rows = SearchMemory.active.order(:id).to_a
    return result("Ma mémoire de recherche est vide. Donnez-moi des synonymes ou des mots clefs (« aide »).") if rows.empty?

    result("Mémoire de recherche (#{rows.size}) :\n" + rows.map { |m| "##{m.id} #{describe(m)}" }.join("\n"))
  end

  # ------------------------------------------------------- retours de l'agent d'usage
  def insights(days = 7)
    reports = (0...days).map { |i| UsageReport.build(UsageReport::ZONE.today - i) }
    users = reports.flat_map { |r| r[:users] }
    searches = users.flat_map { |u| u[:searches] }
    zero = searches.select { |q| q[:results] == 0 }
    journeys = users.flat_map { |u| u[:journeys] }
    carts = journeys.select { |j| j[:added] }
    vias = users.each_with_object(Hash.new(0)) { |u, h| u[:vias].each { |k, v| h[k] += v } }
    return result("Aucune recherche enregistrée ces #{days} derniers jours : l'agent d'usage n'a pas encore de données.") if searches.empty? && carts.empty?

    lines = [ "Qualité de la recherche — #{days} derniers jours (d'après l'agent d'usage) :" ]
    lines << "• #{searches.size} recherche(s), dont #{zero.size} sans résultat (#{pct(zero.size, searches.size)} %)."
    unless carts.empty?
      qs = carts.map { |j| j[:queries].size }
      lines << "• #{carts.size} article(s) mis au panier : #{(qs.sum / qs.size.to_f).round(1)} requête(s) en moyenne avant l'ajout, #{(carts.sum { |j| j[:seconds].to_i } / carts.size.to_f / 60).round(1)} min, #{(carts.sum { |j| j[:clicks] } / carts.size.to_f).round(1)} clics."
      lines << "• #{carts.count { |j| j[:queries].size >= 3 }} parcours avec 3 requêtes ou plus (recherche difficile)."
    end
    lines << "• Moyen (clics) : barre de recherche #{vias['recherche']}, listes #{vias['liste']}, images #{vias['image']}."
    top0 = zero.map { |q| q[:q].downcase }.tally.sort_by { |q, n| [ -n, q ] }.first(8)
    lines << "• Sans résultat : " + top0.map { |q, n| "« #{q} » (#{n}×)" }.join(", ") if top0.any?
    pending = SearchMemory.where(status: "suggested").count
    lines << "• #{SearchMemory.active.count} élément(s) en mémoire, #{pending} suggestion(s) en attente (« suggestions »)."
    result(lines.join("\n"))
  end

  def suggestions(days = 14)
    created = build_suggestions(days)
    rows = SearchMemory.where(status: "suggested").order(:id).to_a
    return result("Aucune suggestion : les recherches des #{days} derniers jours retrouvent déjà leurs articles (ou aucune donnée d'usage).") if rows.empty?

    lines = rows.map { |m| "##{m.id} « #{m.value} » → #{m.target_label} #{m.note}" }
    result("#{created.positive? ? "#{created} nouvelle(s) suggestion(s) d'après les parcours réels. " : ''}Mots clefs proposés :\n#{lines.join("\n")}\n\nRépondez « valide 12 13 », « valide tout » ou « ignore 14 ».")
  end

  def decide(arg, status)
    rows = SearchMemory.where(status: "suggested")
    rows = rows.where(id: arg.scan(/\d+/).map(&:to_i)) unless arg =~ /\Atout|toutes\z/i
    return result("Aucune suggestion en attente correspondante (« suggestions » pour la liste).") if rows.empty?

    list = rows.to_a
    rows.update_all(status: status, created_by_id: @user.id, updated_at: Time.current)
    verb = status == "active" ? "Mémorisé et appliqué" : "Ignoré (je ne le reproposerai pas)"
    result("#{verb} :\n#{list.map { |m| "##{m.id} « #{m.value} » → #{m.target_label}" }.join("\n")}",
           changed: status == "active", updates: status == "active" ? updates_for(list) : [], synonyms: false)
  end

  # ----------------------------------------------------------- règles de classement
  def add_rule(label:, product_has_any: [], query_has_any: [], query_lacks_any: [], points: -100)
    prod = Array(product_has_any).flat_map { |w| SearchMemory.norm(w).split }.uniq
    return result("Une règle doit nommer au moins un mot de l'article concerné.") if prod.empty?

    pts = points.to_i.clamp(-300, 300)
    rule = { product_has_any: prod, query_has_any: Array(query_has_any).flat_map { |w| SearchMemory.norm(w).split }.uniq,
             query_lacks_any: Array(query_lacks_any).flat_map { |w| SearchMemory.norm(w).split }.uniq, points: pts }
    row = SearchMemory.create!(kind: "rule", term: label.to_s[0, 200], value: rule.to_json, created_by_id: @user.id)
    result("Règle ##{row.id} mémorisée et appliquée à tous : #{rule_text(row.term, rule)}", changed: true, synonyms: true)
  end

  def add_rule_from(product_words, lacks, points, has)
    add_rule(label: "#{points.negative? ? 'Descendre' : 'Monter'} #{product_words}#{lacks ? " sauf si la requête contient #{lacks}" : " quand la requête contient #{has}"}",
             product_has_any: SearchMemory.split_list(product_words.gsub(/\s+(?:ou|et)\s+/i, ",")),
             query_lacks_any: lacks ? SearchMemory.split_list(lacks.gsub(/\s+(?:ou|et)\s+/i, ",")) : [],
             query_has_any: has ? SearchMemory.split_list(has.gsub(/\s+(?:ou|et)\s+/i, ",")) : [], points: points)
  end

  def rule_text(label, r)
    parts = [ "articles contenant #{Array(r[:product_has_any]).join(' / ')}" ]
    parts << "quand la requête contient #{Array(r[:query_has_any]).join(' / ')}" if Array(r[:query_has_any]).any?
    parts << "sauf si la requête contient #{Array(r[:query_lacks_any]).join(' / ')}" if Array(r[:query_lacks_any]).any?
    "« #{label} » : #{parts.join(', ')} → #{r[:points].to_i.positive? ? '+' : ''}#{r[:points]} points."
  end

  def disable_rule(id)
    id = id.to_s
    if id.start_with?("m") && (row = SearchMemory.find_by(id: id.delete("m"), kind: "rule"))
      row.destroy
      return result("Règle #{id} supprimée.", changed: true, synonyms: true)
    end
    if SearchMemory::DEFAULT_RULES.any? { |r| r[:id] == id }
      SearchMemory.find_or_create_by!(kind: "rule_off", value: id, status: "active")
      return result("Règle intégrée #{id} désactivée.", changed: true, synonyms: true)
    end
    result("Règle #{id} introuvable.")
  end

  def rules_overview
    SearchMemory.rules_json.map { |r| "#{r[:id]} — #{rule_text(r[:label], r)}" }.join("\n")
  end

  # Explication du classement d'après les mesures du vrai moteur (navigateur).
  def explain_engine
    blocks = Array(@engine).filter_map do |e|
      e = e.with_indifferent_access
      top = Array(e[:top])
      next if top.empty? && Array(e[:targets]).empty?

      lines = [ "Requête « #{e[:q]} » — #{e[:total]} résultat(s). Premiers :" ]
      top.first(3).each_with_index { |t, i| lines << "#{i + 1}. #{t[:designation]} (#{t[:catalog]} #{t[:article]}#{t[:induni].present? ? " · INDUNI #{t[:induni]}" : ''}) score #{t[:score]} — #{t[:why]}" }
      Array(e[:targets]).each { |t| lines << "Article visé : #{t[:designation]} (#{t[:catalog]} #{t[:article]}) rang #{t[:rank]}, score #{t[:score]} — #{t[:why]}" }
      lines.join("\n")
    end
    return result("Je n'ai pas pu mesurer le moteur pour cette requête. Écrivez par exemple « teste tuyau pvc 125 sn4 compact 5m ».") if blocks.empty?

    result(blocks.join("\n\n") + "\n\nPour corriger : « règle : pénalise <mots de l'article> sauf si on tape <mots> », « ajoute les mots clefs … pour <article> » ou « synonyme : … ».")
  end

  # --- outils appelés par le cerveau (Brain) : renvoient un texte, accumulent les effets pour le navigateur
  def tool_call(name, a)
    a = (a || {}).with_indifferent_access
    res =
      case name
      when "add_synonym"   then save_synonym(clean_term(a[:term]), Array(a[:equivalents]).map(&:to_s), one_way: a[:one_way] == true)
      when "add_keywords"  then tool_keywords(a[:target].to_s, Array(a[:keywords]).map(&:to_s))
      when "add_ranking_rule" then add_rule(label: a[:label].to_s, product_has_any: a[:product_has_any], query_has_any: a[:query_has_any], query_lacks_any: a[:query_lacks_any], points: a[:points])
      when "remove_memory" then forget(a[:what].to_s)
      when "disable_rule"  then disable_rule(a[:id])
      when "list_memory"   then result("#{list_memory.reply}\n\nRègles de classement :\n#{rules_overview}")
      when "search_quality" then insights((a[:days] || 7).to_i.clamp(1, 30))
      when "suggestions"   then suggestions
      when "decide_suggestions" then decide(a[:all] == true ? "tout" : Array(a[:ids]).join(" "), a[:accept] == false ? "ignored" : "active")
      else result("Outil inconnu : #{name}")
      end
    absorb(res)
    res.reply
  end

  def tool_keywords(target, words)
    return result("Mots clefs vides.") if words.empty? || SearchMemory.split_list(words.join(",")).empty?

    cands = candidates(target)
    return result("Aucun article ne correspond à « #{target} ».") if cands.empty?
    return ambiguous(cands) if cands.size > 1

    add_keyword_rows(words.flat_map { |w| SearchMemory.split_list(w) }, cands.first)
  end

  def absorb(res)
    @changed = true if res.changed
    @synonyms = true if res.synonyms
    @updates = (@updates || []) + Array(res.updates)
  end

  def collected(reply_text)
    Result.new(reply: reply_text, changed: !!@changed, updates: (@updates || []).uniq { |u| [ u[:catalog], u[:article] ] }, synonyms: !!@synonyms)
  end

  private

  def result(text, changed: false, updates: [], synonyms: false)
    Result.new(reply: text, changed: changed, updates: updates, synonyms: synonyms)
  end

  def pct(a, b) = b.zero? ? 0 : (100.0 * a / b).round

  def clean_term(s) = s.to_s.strip.gsub(/\A[«"“'\s]+|[»"”'\s]+\z/, "")

  def describe(m)
    if m.kind == "synonym"
      "synonyme « #{m.term} » #{m.one_way ? '→' : '='} #{SearchMemory.split_list(m.value).join(', ')}#{m.status == 'suggested' ? ' (suggestion)' : ''}"
    else
      "mots clefs « #{m.value} » → #{m.target_label}#{m.status == 'suggested' ? ' (suggestion)' : ''}"
    end
  end

  def save_synonym(term, values, one_way:)
    row = SearchMemory.where(kind: "synonym", status: "active").find { |m| SearchMemory.norm(m.term) == SearchMemory.norm(term) && m.one_way == one_way }
    if row
      merged = (SearchMemory.split_list(row.value) + values).uniq { |v| SearchMemory.norm(v) }
      row.update!(value: merged.join(", "))
    else
      row = SearchMemory.create!(kind: "synonym", term: term, value: values.join(", "), one_way: one_way, created_by_id: @user.id)
    end
    result("Mémorisé : #{describe(row)}. Appliqué à la recherche pour tous les utilisateurs.", changed: true, synonyms: true)
  end

  def add_keyword_rows(words, target)
    row = SearchMemory.where(kind: "keyword", status: "active", induni_reference: target[:induni_reference],
                             supplier_name: target[:supplier_name], supplier_reference: target[:supplier_reference]).first
    if row
      merged = (SearchMemory.split_list(row.value) + words).uniq { |v| SearchMemory.norm(v) }
      row.update!(value: merged.join(", "))
    else
      row = SearchMemory.create!(kind: "keyword", value: words.join(", "), induni_reference: target[:induni_reference],
                                 supplier_name: target[:supplier_name], supplier_reference: target[:supplier_reference],
                                 target_label: target[:label], created_by_id: @user.id)
    end
    result("Mémorisé : #{describe(row)}. Ces mots font maintenant trouver l'article (#{target[:count]} ligne(s) fournisseur) pour tous les utilisateurs.",
           changed: true, updates: updates_for([ row ]))
  end

  def ambiguous(cands)
    lines = cands.first(8).map { |c| "• #{c[:induni_reference] || c[:supplier_reference]} — #{c[:label]}" }
    result("Plusieurs articles correspondent (#{cands.size}). Précisez avec le n° INDUNI ou la référence :\n#{lines.join("\n")}")
  end

  # Cibles possibles d'un texte : n° INDUNI (9 chiffres), référence fournisseur, ou mots du nom de l'article.
  def candidates(text)
    t = text.to_s.strip
    if t =~ /\b(\d{9})\b/
      e = NomenclatureEntry.where(induni_reference: Regexp.last_match(1)).to_a
      return e.empty? ? [] : [ { induni_reference: e.first.induni_reference, label: "#{e.first.induni_reference} #{e.first.induni_designation}", count: e.size } ]
    end
    ref = t[/\b[A-Za-z0-9][A-Za-z0-9.\-]{4,}\b/]
    if ref && (prods = Product.joins(:supplier).where("LOWER(products.reference) = ?", ref.downcase).to_a).any?
      return prods.map { |p| { supplier_name: p.supplier.name, supplier_reference: p.reference, label: "#{p.supplier.name} #{p.reference} #{p.name}", count: 1 } }
    end
    words = SearchMemory.norm(t).split.reject { |w| w.length < 2 }
    return [] if words.empty?

    entries = NomenclatureEntry.all.select { |e| (n = SearchMemory.norm(e.induni_designation)) && words.all? { |w| n.include?(w) } }.group_by(&:induni_reference)
    found = entries.map { |r, es| { induni_reference: r, label: "#{r} #{es.first.induni_designation}", count: es.size } }
    covered = NomenclatureEntry.where(induni_reference: entries.keys).pluck(:supplier_name, :supplier_reference).to_set
    Product.joins(:supplier).includes(:supplier).select { |p| (n = SearchMemory.norm(p.name)) && words.all? { |w| n.include?(w) } }
           .reject { |p| covered.include?([ p.supplier.name, p.reference ]) }.first(20).each do |p|
      found << { supplier_name: p.supplier.name, supplier_reference: p.reference, label: "#{p.supplier.name} #{p.reference} #{p.name}", count: 1 }
    end
    found
  end

  # Mises à jour à pousser au navigateur de l'administrateur (les autres les reçoivent via /api/products).
  def updates_for(rows) = build_updates(target_keys(rows))

  def target_keys(rows)
    rows.select { |m| m.kind == "keyword" }.flat_map do |m|
      if m.induni_reference.present? then NomenclatureEntry.where(induni_reference: m.induni_reference).map { |e| [ e.supplier_name, e.supplier_reference ] }
      else [ [ m.supplier_name, m.supplier_reference ] ]
      end
    end.uniq
  end

  def build_updates(keys)
    kw = SearchMemory.keywords_by_product
    base = NomenclatureEntry.all.index_by { |e| [ e.supplier_name, e.supplier_reference ] }
    keys.map { |sup, ref| { catalog: sup, article: ref, induniKeywords: [ base[[ sup, ref ]]&.search_keywords, kw[[ sup, ref ]] ].compact_blank.join(" ; ").presence } }
  end

  # Mots clefs proposés d'après les parcours réels : ce qui a été tapé avant un ajout au panier et qui ne
  # figure pas dans le texte de l'article finalement choisi.
  def build_suggestions(days)
    counts = Hash.new(0); target = {}
    days.times do |i|
      UsageReport.build(UsageReport::ZONE.today - i)[:users].each do |u|
        u[:journeys].each do |j|
          next unless j[:added] && j[:article].present? && j[:catalog].present?

          j[:queries].uniq.each do |q|
            key = [ SearchMemory.norm(q), j[:catalog], j[:article] ]
            counts[key] += 1; target[key] = [ q, j[:designation] ]
          end
        end
      end
    end
    kw = SearchMemory.keywords_by_product
    nom = NomenclatureEntry.all.index_by { |e| [ e.supplier_name, e.supplier_reference ] }
    made = 0
    counts.sort_by { |_, n| -n }.first(30).each do |(qn, catalog, article), n|
      next if qn.blank?
      next if SearchMemory.where(kind: "keyword", supplier_name: catalog, supplier_reference: article).any? { |m| SearchMemory.split_list(m.value).any? { |v| SearchMemory.norm(v) == qn } }

      prod = Product.joins(:supplier).find_by(suppliers: { name: catalog }, reference: article)
      next unless prod

      text = SearchMemory.norm([ prod.name, prod.descriptif, prod.famille, prod.sous_famille, nom[[ catalog, article ]]&.induni_designation,
                                 nom[[ catalog, article ]]&.search_keywords, kw[[ catalog, article ]] ].join(" "))
      next if qn.split.all? { |w| text.include?(w) } # le mot figure déjà dans l'article

      SearchMemory.create!(kind: "keyword", status: "suggested", source: "suggestion", value: target[[ qn, catalog, article ]].first,
                           supplier_name: catalog, supplier_reference: article, target_label: "#{catalog} #{article} #{target[[ qn, catalog, article ]].last}".strip,
                           note: "(tapé avant l'ajout au panier, #{n}×)")
      made += 1
    end
    made
  end
end
