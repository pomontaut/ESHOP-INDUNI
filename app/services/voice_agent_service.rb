# Agent de commande vocale (environnement test « Développement » uniquement).
#
# Conversation texte (la dictée et la lecture à voix haute sont faites par le
# navigateur) : Claude cherche des articles dans le catalogue VISIBLE par
# l'utilisateur et propose des lignes de panier. Le serveur ne touche jamais au
# panier ni à une commande : il renvoie `cart_actions` que le navigateur applique
# avec addCart()/setQty() (mêmes règles que la saisie manuelle : multiples de
# longueur de tuyau, fournisseur unique par panier). L'envoi reste un clic humain.
#
# Prix confidentiels (Supplier#confidential_pricing) : jamais transmis au modèle.
class VoiceAgentService
  class AgentError < StandardError; end

  MODEL = :"claude-sonnet-5-5"
  MAX_TURNS = 6
  MAX_RESULTS = 8
  STOP_WORDS = %w[le la les un une des de du d l et ou en pour avec sans sur a au aux mm cm x fois piece pieces pièce pièces].freeze

  TOOLS = [
    {
      name: "search_products",
      description: "Cherche des articles dans le catalogue (désignation, référence, famille). " \
                   "Donne les mots-clés utiles (ex. « coude pvc 110 90° »). Renvoie au plus #{MAX_RESULTS} articles.",
      input_schema: {
        type: "object",
        properties: { query: { type: "string", description: "Mots-clés de recherche" } },
        required: [ "query" ]
      }
    },
    {
      name: "add_to_cart",
      description: "Propose l'ajout d'un article au panier de l'utilisateur (il le verra et pourra le corriger). " \
                   "Utilise exactement `catalog` et `article` renvoyés par search_products.",
      input_schema: {
        type: "object",
        properties: {
          catalog: { type: "string" },
          article: { type: "string" },
          qty: { type: "number", description: "Quantité dans l'unité de l'article" }
        },
        required: [ "catalog", "article", "qty" ]
      }
    }
  ].freeze

  attr_reader :cart_actions

  # messages : [{ "role" => "user"|"assistant", "content" => "texte" }, ...]
  def initialize(user:, messages:, cart_supplier: nil, include_test_only: true, client: nil)
    @user = user
    @messages = messages
    @cart_supplier = cart_supplier.presence
    @include_test_only = include_test_only
    @client = client
    @cart_actions = []
  end

  # Renvoie { reply: "...", cart_actions: [...] }
  def call
    raise AgentError, "Clé ANTHROPIC_API_KEY absente de la configuration du serveur." if ENV["ANTHROPIC_API_KEY"].blank? && @client.nil?

    convo = @messages.map { |m| { role: m["role"].to_s, content: m["content"].to_s } }
    MAX_TURNS.times do
      response = client.messages.create(model: MODEL, max_tokens: 1024, system: system_prompt, tools: TOOLS, messages: convo)
      blocks = response.content.map { |b| block_to_h(b) }
      tool_uses = blocks.select { |b| b[:type] == "tool_use" }
      if tool_uses.empty?
        return { reply: blocks.select { |b| b[:type] == "text" }.map { |b| b[:text] }.join(" ").strip, cart_actions: @cart_actions }
      end
      convo << { role: "assistant", content: blocks }
      convo << { role: "user", content: tool_uses.map { |t|
        { type: "tool_result", tool_use_id: t[:id], content: run_tool(t[:name], t[:input] || {}).to_json }
      } }
    end
    { reply: "Désolé, je n'ai pas réussi à finaliser. Reformulez votre besoin.", cart_actions: @cart_actions }
  rescue Anthropic::Errors::APIError => e
    raise AgentError, "Erreur du service IA : #{e.message}"
  end

  # --- Outils (publics pour les tests) ---

  def search(query)
    words = query.to_s.downcase.scan(/[[:alnum:]°]+/).reject { |w| STOP_WORDS.include?(w) }.uniq.first(8)
    return [] if words.empty?
    scope = visible_products
    cond = words.map { "LOWER(products.name || ' ' || COALESCE(products.reference,'') || ' ' || COALESCE(products.sous_famille,'')) LIKE ?" }
    candidates = scope.where(cond.join(" OR "), *words.map { |w| "%#{ActiveRecord::Base.sanitize_sql_like(w)}%" }).limit(600).to_a
    candidates.map { |p|
      hay = "#{p.name} #{p.reference} #{p.sous_famille}".downcase
      [ words.count { |w| hay.include?(w) }, p ]
    }.sort_by { |score, p| [ -score, p.name.to_s ] }.first(MAX_RESULTS).map { |_, p| product_json(p) }
  end

  private

  def visible_products
    visible = @user.effective_visible_suppliers
    visible -= Supplier::TEST_ONLY_NAMES unless @include_test_only
    scope = Product.joins(:supplier).includes(:supplier).where.not(famille: nil).where(suppliers: { name: visible })
              .where.not("suppliers.name = ? AND products.famille != ?", "Swisspor", "Isolation")
    scope = scope.where(suppliers: { name: @cart_supplier }) if @cart_supplier
    scope
  end

  def product_json(p)
    confidential = p.supplier&.confidential_pricing?
    {
      catalog: p.supplier&.name, article: p.reference, designation: p.name, unite: p.unite,
      prix: confidential ? "confidentiel (accords cadre)" : p.unit_price.to_f
    }
  end

  def run_tool(name, input)
    case name
    when "search_products"
      results = search(input["query"])
      results.empty? ? { results: [], note: "Aucun article trouvé : reformule ou demande une précision." } : { results: results }
    when "add_to_cart"
      p = visible_products.find_by(suppliers: { name: input["catalog"] }, reference: input["article"].to_s)
      qty = input["qty"].to_f
      return { error: "Article introuvable (utilise catalog/article de search_products)." } unless p
      return { error: "Quantité invalide." } unless qty > 0
      if (other = @cart_actions.first) && other[:catalog] != p.supplier.name
        return { error: "Un panier = un seul fournisseur (#{other[:catalog]}). Demande à l'utilisateur de choisir." }
      end
      @cart_actions << { catalog: p.supplier.name, article: p.reference, designation: p.name, qty: qty }
      { ok: true, ajoute: "#{qty} × #{p.name}" }
    else
      { error: "Outil inconnu." }
    end
  end

  def block_to_h(b)
    case b.type.to_s
    when "text" then { type: "text", text: b.text }
    when "tool_use" then { type: "tool_use", id: b.id, name: b.name, input: b.input.to_h.transform_keys(&:to_s) }
    else { type: "text", text: "" }
    end
  end

  def client
    @client ||= Anthropic::Client.new
  end

  def system_prompt
    <<~P
      Tu es l'assistant de commande vocale de l'e-shop d'Induni & Cie SA (construction, Suisse romande).
      L'utilisateur te parle (transcription automatique, possibles erreurs) : réponds en français, très court
      (1 à 2 phrases, lu à voix haute), sans mise en forme ni listes à puces.
      Démarche : comprendre le besoin (article, dimension, quantité), appeler search_products, puis
      add_to_cart pour l'article choisi. Si plusieurs articles conviennent (variantes, fournisseurs, angles),
      pose UNE question courte avec 2-3 choix plutôt que de deviner. Si tout est clair, ajoute directement.
      Règles : un panier = un seul fournisseur#{@cart_supplier ? " (le panier est déjà chez #{@cart_supplier})" : ""} ;
      n'invente jamais un article ni un prix ; ne cite jamais de prix pour un article « confidentiel » ;
      tu ne passes ni n'envoies jamais de commande — l'utilisateur valide lui-même depuis le panier ;
      diamètre : exactement celui demandé, jamais une approximation. Ne parle pas de livraison ni de chantier.
    P
  end
end
