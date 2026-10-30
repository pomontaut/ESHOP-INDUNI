# Cerveau conversationnel de l'agent « moteur de recherche » : comprend le français libre (remarques,
# questions « pourquoi », consignes) et agit en appelant les outils de SearchAgent (mémoire de synonymes,
# mots clefs, règles de classement, bilan, suggestions). Utilise l'API Claude quand ANTHROPIC_API_KEY est
# configurée ; sinon SearchAgent retombe sur les commandes à formulation fixe.
class SearchAgent
  class Brain
    MODEL = ENV.fetch("SEARCH_AGENT_MODEL", "claude-sonnet-5-5")
    MAX_ROUNDS = 8

    TOOLS = [
      { name: "add_synonym", description: "Mémorise un synonyme du bandeau de recherche (appliqué tout de suite à tous les utilisateurs). one_way=true : seul le mot tapé trouve les équivalents ; sinon dans les deux sens.",
        input_schema: { type: "object", properties: { term: { type: "string" }, equivalents: { type: "array", items: { type: "string" } }, one_way: { type: "boolean" } }, required: %w[term equivalents] } },
      { name: "add_keywords", description: "Ajoute des mots clefs de recherche à un article. target = n° INDUNI (9 chiffres, toutes les lignes fournisseur), référence fournisseur ou nom de l'article ; si plusieurs articles correspondent l'outil les liste : redemande alors la précision à l'administrateur.",
        input_schema: { type: "object", properties: { target: { type: "string" }, keywords: { type: "array", items: { type: "string" } } }, required: %w[target keywords] } },
      { name: "add_ranking_rule", description: "Crée une règle de classement appliquée à tous : ajoute `points` (-300 à +300) au score d'un article qui contient un des mots product_has_any (désignation, descriptif, familles), quand la requête contient un des mots query_has_any (optionnel) et AUCUN des mots query_lacks_any (optionnel). Exemple : descendre les tubes de drainage (product_has_any drainage, drain, perfore) sauf si la requête contient drain/drainage (points -120).",
        input_schema: { type: "object", properties: { label: { type: "string" }, product_has_any: { type: "array", items: { type: "string" } }, query_has_any: { type: "array", items: { type: "string" } }, query_lacks_any: { type: "array", items: { type: "string" } }, points: { type: "integer" } }, required: %w[label product_has_any points] } },
      { name: "disable_rule", description: "Désactive/supprime une règle de classement par son id (b-… = intégrée, m12 = apprise).", input_schema: { type: "object", properties: { id: { type: "string" } }, required: %w[id] } },
      { name: "remove_memory", description: "Oublie un élément de mémoire (synonyme ou mots clefs) par id numérique ou par mot.", input_schema: { type: "object", properties: { what: { type: "string" } }, required: %w[what] } },
      { name: "list_memory", description: "Liste la mémoire de recherche et les règles de classement actives.", input_schema: { type: "object", properties: {} } },
      { name: "search_quality", description: "Retours de l'agent d'usage sur la qualité de la recherche (recherches sans résultat, requêtes et temps avant l'ajout au panier, moyen utilisé).", input_schema: { type: "object", properties: { days: { type: "integer" } } } },
      { name: "suggestions", description: "Propose des mots clefs d'après les parcours réels (ce qui a été tapé avant un ajout au panier).", input_schema: { type: "object", properties: {} } },
      { name: "decide_suggestions", description: "Valide (accept=true) ou ignore (accept=false) des suggestions par ids, ou toutes (all=true).",
        input_schema: { type: "object", properties: { ids: { type: "array", items: { type: "integer" } }, all: { type: "boolean" }, accept: { type: "boolean" } }, required: %w[accept] } }
    ].freeze

    SYSTEM = <<~TXT.freeze
      Tu es l'agent « moteur de recherche » de l'e-shop d'Induni & Cie SA (matériaux de construction, Suisse). Tu parles à un
      administrateur (le propriétaire) qui te fait des retours en direct sur le bandeau de recherche et dont tu dois APPLIQUER
      les remarques, pas seulement les noter. Réponds en français, court et direct.

      Fonctionnement du moteur (navigateur) : chaque article reçoit un score. Points pour chaque mot tapé retrouvé dans la
      désignation, le descriptif, les familles, la référence, le n° INDUNI, les mots clefs INDUNI (nomenclature + mémoire) et les
      synonymes ; gros bonus quand tous les mots sont retrouvés, pour SN4/SN8/SN2, PVC, compact, diamètre exact et longueur
      exacte ; pénalité pour une autre longueur ; puis les règles de classement mémorisées (points en plus ou en moins).
      Les articles sont triés par score décroissant.

      Ton rôle :
      - Une question « pourquoi ? » : explique la cause à partir du « contexte moteur » mesuré (scores, mots retrouvés/absents,
        règles) ; puis, si l'administrateur exprime une attente de classement, corrige-la sans demander confirmation.
      - Un mauvais classement (« je tombe sur X au lieu de Y ») : choisis le correctif le plus général et le plus sûr :
        règle de classement (add_ranking_rule) pour un type d'article à descendre/monter, mots clefs (add_keywords) pour un article
        précis, synonyme (add_synonym) pour un mot différent. Applique-le avec l'outil, puis indique ce que tu as appliqué et
        invite à vérifier avec « teste <requête> ».
      - Un mot ou une expression à retenir : add_keywords ou add_synonym.
      - Des questions sur la qualité : search_quality, suggestions. Ne valide des suggestions que si l'administrateur le demande.
      - Ne demande une précision que si c'est vraiment ambigu (plusieurs articles possibles) ; n'invente jamais un n° d'article.
      - Tout ce que tu mémorises s'applique immédiatement à tous les utilisateurs de l'e-shop : sois précis et prudent
        sur la portée (une règle trop large dégrade la recherche).
    TXT

    def self.available?
      ENV["ANTHROPIC_API_KEY"].present?
    end

    def initialize(agent, user, client: nil)
      @agent = agent
      @user = user
      @client = client
    end

    def run(text, engine)
      messages = history + [ { role: "user", content: user_content(text, engine) } ]
      final = ""
      MAX_ROUNDS.times do
        resp = client.messages.create(model: MODEL, max_tokens: 2000, system: SYSTEM, tools: TOOLS, messages: messages)
        blocks = resp.content.map { |b| block_hash(b) }
        texts = blocks.select { |b| b[:type] == "text" }.map { |b| b[:text] }
        calls = blocks.select { |b| b[:type] == "tool_use" }
        final = texts.join("\n").strip
        break if calls.empty?

        messages << { role: "assistant", content: blocks }
        messages << { role: "user", content: calls.map { |c| { type: "tool_result", tool_use_id: c[:id], content: @agent.tool_call(c[:name], c[:input]) } } }
      end
      final = "C'est fait." if final.blank?
      @agent.collected(final)
    end

    private

    def client
      @client ||= Anthropic::Client.new
    end

    def history
      SearchAgentMessage.order(:id).last(14).reject { |m| m.content.blank? }.map { |m| { role: m.role == "agent" ? "assistant" : "user", content: m.content.to_s[0, 3000] } }
        .then { |h| h.last&.dig(:role) == "user" ? h[0...-1] : h } # le message courant est ajouté après
        .then { |h| h.drop_while { |m| m[:role] != "user" } }
        .then { |h| merge_roles(h) }
    end

    def merge_roles(h)
      h.each_with_object([]) { |m, out| out.last && out.last[:role] == m[:role] ? out.last[:content] += "\n#{m[:content]}" : out << m.dup }
    end

    def user_content(text, engine)
      ctx = Array(engine).presence
      return text unless ctx

      "#{text}\n\n[Contexte moteur — mesuré dans le navigateur de l'administrateur avec le vrai moteur, pour les requêtes de son message]\n#{JSON.pretty_generate(ctx)[0, 12_000]}"
    end

    def block_hash(b)
      type = b.respond_to?(:type) ? b.type.to_s : b[:type].to_s
      case type
      when "text" then { type: "text", text: b.respond_to?(:text) ? b.text : b[:text] }
      when "tool_use"
        input = b.respond_to?(:input) ? b.input : b[:input]
        { type: "tool_use", id: b.respond_to?(:id) ? b.id : b[:id], name: (b.respond_to?(:name) ? b.name : b[:name]).to_s, input: input.respond_to?(:to_h) ? input.to_h : input }
      else { type: type }
      end
    end
  end
end
