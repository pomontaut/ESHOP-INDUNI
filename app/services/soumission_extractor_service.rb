# Lit une soumission au format CAN (PDF) et en extrait les positions SURLIGNÉES : jaune = fourniture
# seule, autre couleur = fourniture et pose (même convention que l'outil « gestion soumission »).
# Utilise l'API Claude (le PDF est lu visuellement, les surlignages sont donc visibles).
class SoumissionExtractorService
  class ExtractionError < StandardError; end

  MODEL = DevisExtractorService::MODEL

  def initialize(pdf_bytes) = @pdf_bytes = pdf_bytes

  # => [{ pos:, designation:, quantity:, unit:, cfc:, chapter:, highlight: "jaune"|"autre" }, ...]
  def extract
    raise ExtractionError, "Clé ANTHROPIC_API_KEY absente de la configuration du serveur." if ENV["ANTHROPIC_API_KEY"].blank?

    response = Anthropic::Client.new.messages.create(
      model: MODEL, max_tokens: 16000,
      output_config: { format_: { schema: schema } },
      messages: [ { role: "user", content: [
        { type: "document", source: { type: "base64", media_type: "application/pdf", data: Base64.strict_encode64(@pdf_bytes) } },
        { type: "text", text: prompt }
      ] } ]
    )
    block = response.content.find { |b| b.type == :text }
    raise ExtractionError, "Réponse vide de l'IA" unless block
    (JSON.parse(block.text, symbolize_names: true)[:items] || [])
  rescue Anthropic::Errors::APIError => e
    raise ExtractionError, "Erreur du service d'extraction IA : #{e.message}"
  rescue JSON::ParserError
    raise ExtractionError, "Le service d'extraction IA a renvoyé une réponse illisible."
  end

  private

  def schema
    item = { type: "object", additionalProperties: false,
             properties: { pos: { type: "string" }, designation: { type: "string" }, quantity: { type: [ "number", "null" ] },
                           unit: { type: "string" }, cfc: { type: "string" }, chapter: { type: "string" },
                           highlight: { type: "string", enum: %w[jaune autre] } },
             required: %w[pos designation quantity unit cfc chapter highlight] }
    { type: "object", properties: { items: { type: "array", items: item } }, required: [ "items" ], additionalProperties: false }
  end

  def prompt
    <<~PROMPT
      Ce document est une soumission de construction (format CAN, descriptif avec positions, quantités et unités).
      Extrait UNIQUEMENT les positions dont le texte est SURLIGNÉ (marqueur fluo), page par page, sans en omettre.
      - highlight = "jaune" si le surlignage est jaune (fourniture seule), "autre" pour toute autre couleur (fourniture et pose).
      - pos = numéro de position tel qu'imprimé ; designation = texte complet de la position (matériau, dimensions, qualité) sans les prix ;
        quantity / unit = quantité et unité de la position (null si absente) ; cfc = code CFC si visible, sinon "" ;
        chapter = titre du chapitre / sous-chapitre.
      - N'invente rien : un texte illisible ou non surligné n'est pas extrait. Ne recopie AUCUN prix de la soumission.
    PROMPT
  end
end
