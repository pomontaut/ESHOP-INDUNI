# Extracts ordered line items from a supplier quote (devis) PDF using the Claude API.
class DevisExtractorService
  class ExtractionError < StandardError; end

  MODEL = :"claude-opus-4-8"
  NO_CATEGORY = "".freeze

  SURCHARGE_SCHEMA = {
    type: "object",
    properties: {
      label: { type: "string" },
      amount: { type: "number" }
    },
    required: %w[label amount],
    additionalProperties: false
  }.freeze

  # `taxonomy` is an array of [famille, sous_famille] pairs (sous_famille may
  # be nil) already used in our catalog for this supplier — used to suggest,
  # for articles we don't carry yet, the closest existing category rather
  # than inventing a new one.
  def initialize(pdf_bytes, supplier_name, taxonomy = [])
    @pdf_bytes = pdf_bytes
    @supplier_name = supplier_name
    @category_options = taxonomy.map { |famille, sous_famille| combine_category(famille, sous_famille) }.uniq.sort
  end

  # Returns { items: [...], surcharges: [...] } (Hashes with symbol keys, item variants excluded).
  def extract
    if ENV["ANTHROPIC_API_KEY"].blank?
      raise ExtractionError, "Clé ANTHROPIC_API_KEY absente de la configuration du serveur."
    end

    response = client.messages.create(
      model: MODEL,
      max_tokens: 16000,
      output_config: { format_: { schema: schema } },
      messages: [ {
        role: "user",
        content: [
          {
            type: "document",
            source: { type: "base64", media_type: "application/pdf", data: Base64.strict_encode64(@pdf_bytes) }
          },
          { type: "text", text: prompt }
        ]
      } ]
    )

    text_block = response.content.find { |b| b.type == :text }
    raise ExtractionError, "Réponse vide de l'IA" unless text_block

    parsed = JSON.parse(text_block.text, symbolize_names: true)
    items = (parsed[:items] || []).reject { |item| item[:is_variant] }
    items.each { |item| item[:suggested_famille], item[:suggested_sous_famille] = split_category(item[:suggested_category]) }
    { items: items, surcharges: parsed[:surcharges] || [] }
  rescue Anthropic::Errors::APIError => e
    raise ExtractionError, "Erreur du service d'extraction IA : #{e.message}"
  rescue JSON::ParserError
    raise ExtractionError, "Le service d'extraction IA a renvoyé une réponse illisible."
  end

  private

  def combine_category(famille, sous_famille)
    sous_famille.present? ? "#{famille} > #{sous_famille}" : famille.to_s
  end

  def split_category(combined)
    return [ nil, nil ] if combined.blank?
    famille, sous_famille = combined.split(" > ", 2)
    [ famille, sous_famille ]
  end

  def item_schema
    {
      type: "object",
      properties: {
        reference: { type: "string" },
        designation: { type: "string" },
        quantity: { type: "number" },
        unit: { type: "string" },
        unit_price: { type: [ "number", "null" ] },
        is_variant: { type: "boolean" },
        suggested_category: { type: "string", enum: @category_options + [ NO_CATEGORY ] }
      },
      required: %w[reference designation quantity unit unit_price is_variant suggested_category],
      additionalProperties: false
    }
  end

  def schema
    {
      type: "object",
      properties: {
        items: { type: "array", items: item_schema },
        surcharges: { type: "array", items: SURCHARGE_SCHEMA }
      },
      required: %w[items surcharges],
      additionalProperties: false
    }
  end

  def client
    @client ||= Anthropic::Client.new
  end

  def prompt
    <<~PROMPT
      Ce document est un devis / offre de prix du fournisseur "#{@supplier_name}".
      Extrait TOUTES les lignes d'articles physiques commandables avec leur quantité, dans `items`,
      et les suppléments proportionnels au poids/volume de la commande (carburant, énergie, etc.) dans
      `surcharges`.

      Règles pour `items` :
      - Parcours le document EN ENTIER, page par page, et extrait CHAQUE ligne d'article de CHAQUE tableau,
        même s'il y en a beaucoup (10, 20 lignes ou plus). Ne t'arrête jamais en cours de tableau : si le calcul
        du prix net d'une ligne te semble complexe ou incertain, inclus quand même la ligne avec ton meilleur
        calcul plutôt que de l'omettre.
      - Une même référence peut apparaître PLUSIEURS FOIS dans le devis avec des quantités différentes (ex. deux
        tronçons du même tuyau commandés séparément) : ce sont des lignes distinctes à part entière, PAS des
        variantes — inclus chaque occurrence comme un item séparé avec sa propre quantité.
      - N'inclus PAS les frais de transport, de déchargement, d'emballage ou tout autre frais de service
        de base (ceux-ci sont recalculés séparément par notre propre système selon le chantier).
      - Marque `is_variant: true` UNIQUEMENT pour une ligne qui propose explicitement un article alternatif /
        optionnel à un autre (souvent introduite par "* VARIANTE", "Variante", "option", ou mentionnée en aparté
        avec un prix alternatif dans le texte d'une autre ligne) — PAS pour une répétition légitime de la même
        référence avec une quantité différente (voir règle ci-dessus). Ces lignes variantes seront ignorées
        ensuite, inclus-les quand même avec ce marqueur plutôt que de les omettre.
      - `reference` = la référence / n° d'article du fournisseur tel qu'imprimé (colonne "No", "N° d'art.",
        "Référence", "Kundenartikel-Nr.", etc). Si le scan est de mauvaise qualité, fais de ton mieux pour
        reconstituer la référence à partir du contexte, sans l'inventer si elle est illisible (dans ce cas laisse
        une chaîne vide).
      - `designation` = la désignation / description de l'article (peut être multi-lignes dans le devis), résumée
        en une phrase claire.
      - `quantity` = la quantité commandée pour cette ligne, dans l'unité `unit` (voir ci-dessous — pas dans une
        unité secondaire alternative si plusieurs sont données, ex. un poids en kg ET un nombre de sacs/palettes).
      - `unit` = l'unité de mesure de `quantity` telle qu'indiquée dans le devis (M, PCE, P, KG, etc.).
      - `unit_price` = le prix unitaire NET par unité de `quantity`, après remise(s), en CHF, ou null si absent.
        Vérifie toujours ton calcul en multipliant `unit_price` par `quantity` : le résultat doit correspondre
        (aux arrondis près) au montant total imprimé pour cette ligne. Si le calcul détaillé ci-dessous ne
        reconcilie pas avec ce montant total, utilise `unit_price` = montant total imprimé ÷ `quantity`.

        Cas 1 — remise simple sur plusieurs lignes (structure HGC) : un prix brut et un montant brut sur la ligne
        de l'article, puis en dessous un "Rabais X %" et enfin une ligne "Montant hors TVA" qui donne le prix net
        par unité ET le montant net total de la ligne. C'est CE prix net (celui de la ligne "Montant hors TVA",
        pas le prix brut de la ligne principale) qu'il faut retourner dans `unit_price` — jamais le prix brut
        avant remise. Si seul le montant net total de la ligne est donné sans prix net unitaire explicite,
        calcule `unit_price` = montant net total ÷ `quantity`.

          Pos  Article                    Désignations                Quantité/UQ   Prix CHF   UP    Montant CHF
          7'200 100058451                 Kerakoll Geolite Magma 20   10'500 KG     2.29       1 KG  24'045.00
                                                                        420 SAC
                                           Rabais                                    42.50- %          10'219.13-
                                           Montant hors TVA                          1.32              13'825.87
        → quantity = 10500, unit = "KG", unit_price = 1.32 (PAS 2.29, qui est le prix brut avant les 42.5% de
          remise ; 1.32 = 13'825.87 ÷ 10'500, cohérent avec le montant net affiché).

        Cas 2 — remises en cascade sur une seule ligne, avec DEUX pourcentages dans la colonne "Remise %"
        (structure Canplast). Certains devis appliquent DEUX remises successives au prix de liste ("Prix u.") :
        applique-les dans l'ordre à la suite l'une de l'autre. ATTENTION : si un pourcentage est imprimé avec un
        signe "-" devant (ex. "-35%"), et que le document précise quelque part une note du type "Rabais avec
        symbole "-" = Hausse de prix", ce pourcentage est en réalité une HAUSSE (multiplie par (1 + le taux)) et
        non une remise (ne le soustrais pas) ; un pourcentage sans signe "-" reste une remise normale
        (multiplie par (1 - le taux)).

          N°       Désignation                              Qté       Prix u.   Remise %      Montant
          LDT3155  Tuyau PVC compact ... Ø 315 x 6.2 mm      245,28 M  34,35     -35%   48%    5 914,61
        → prix net = 34.35 × (1 + 0.35) × (1 - 0.48) = 24.11 CHF/M (PAS 34.35, ni un simple 34.35×(1-0.35)) ;
          vérification : 24.11 × 245.28 ≈ 5 914,61, qui correspond bien au montant imprimé.
      - `suggested_category` = la catégorie de notre catalogue qui correspond le mieux à cet article, à choisir
        EXACTEMENT parmi la liste ci-dessous (recopie une valeur telle quelle, n'en invente pas une autre) :
        #{@category_options.presence&.map { |c| "  - #{c}" }&.join("\n") || "  (aucune catégorie connue pour ce fournisseur)"}
        Si aucune catégorie de la liste ne convient raisonnablement, retourne une chaîne vide "".

      Règles pour `surcharges` :
      - Capture les suppléments proportionnels appliqués à l'ensemble de la commande selon son poids/volume,
        typiquement nommés "Supplément carburant", "Supplément énergie" ou similaire (souvent exprimés en % avec
        un montant CHF en face). N'y mets PAS les frais de transport/livraison de base ni la TVA.
      - `label` = le nom du supplément tel qu'imprimé (ex. "Supplément carburant").
      - `amount` = le montant CHF de ce supplément tel qu'imprimé (pas le pourcentage), ex. 5.04 pour
        "Supplément carburant 6.00 %  84.00  5.04" (5.04 est le montant CHF, 84.00 la base de calcul, 6.00% le taux).
      - S'il n'y a aucun supplément de ce type, retourne un tableau vide.

      Réponds uniquement avec le JSON structuré demandé, sans texte additionnel.
    PROMPT
  end
end
