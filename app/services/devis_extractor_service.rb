# Extracts ordered line items from a supplier quote (devis) PDF using the Claude API.
class DevisExtractorService
  class ExtractionError < StandardError; end

  MODEL = :"claude-opus-4-8"

  ITEM_SCHEMA = {
    type: "object",
    properties: {
      reference: { type: "string" },
      designation: { type: "string" },
      quantity: { type: "number" },
      unit: { type: "string" },
      unit_price: { type: [ "number", "null" ] },
      is_variant: { type: "boolean" }
    },
    required: %w[reference designation quantity unit unit_price is_variant],
    additionalProperties: false
  }.freeze

  SCHEMA = {
    type: "object",
    properties: {
      items: { type: "array", items: ITEM_SCHEMA }
    },
    required: [ "items" ],
    additionalProperties: false
  }.freeze

  def initialize(pdf_bytes, supplier_name)
    @pdf_bytes = pdf_bytes
    @supplier_name = supplier_name
  end

  # Returns an array of line items (Hash with symbol keys), variants excluded.
  def extract
    if ENV["ANTHROPIC_API_KEY"].blank?
      raise ExtractionError, "Clé ANTHROPIC_API_KEY absente de la configuration du serveur."
    end

    response = client.messages.create(
      model: MODEL,
      max_tokens: 8000,
      output_config: { format_: { schema: SCHEMA } },
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

    items = JSON.parse(text_block.text, symbolize_names: true)[:items] || []
    items.reject { |item| item[:is_variant] }
  rescue Anthropic::Errors::APIError => e
    raise ExtractionError, "Erreur du service d'extraction IA : #{e.message}"
  rescue JSON::ParserError
    raise ExtractionError, "Le service d'extraction IA a renvoyé une réponse illisible."
  end

  private

  def client
    @client ||= Anthropic::Client.new
  end

  def prompt
    <<~PROMPT
      Ce document est un devis / offre de prix du fournisseur "#{@supplier_name}".
      Extrait TOUTES les lignes d'articles physiques commandables avec leur quantité.

      Règles strictes :
      - N'inclus PAS les frais de transport, de déchargement, d'emballage ou tout autre frais de service.
      - Marque `is_variant: true` pour toute ligne qui est une variante / option alternative non retenue par défaut
        (souvent introduite par "* VARIANTE", "Variante", "option", ou mentionnée en aparté avec un prix alternatif
        dans le texte d'une autre ligne). Ces lignes seront ignorées ensuite, inclus-les quand même avec ce marqueur
        plutôt que de les omettre.
      - `reference` = la référence / n° d'article du fournisseur tel qu'imprimé (colonne "No", "N° d'art.",
        "Référence", "Kundenartikel-Nr.", etc). Si le scan est de mauvaise qualité, fais de ton mieux pour
        reconstituer la référence à partir du contexte, sans l'inventer si elle est illisible (dans ce cas laisse
        une chaîne vide).
      - `designation` = la désignation / description de l'article (peut être multi-lignes dans le devis), résumée
        en une phrase claire.
      - `quantity` = la quantité commandée pour cette ligne.
      - `unit` = l'unité de mesure telle qu'indiquée dans le devis (M, PCE, P, KG, etc.).
      - `unit_price` = le prix unitaire net (après remise) tel qu'indiqué dans le devis, en CHF, ou null si absent.

      Réponds uniquement avec le JSON structuré demandé, sans texte additionnel.
    PROMPT
  end
end
