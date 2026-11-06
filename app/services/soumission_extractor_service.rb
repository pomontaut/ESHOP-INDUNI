# Lit une soumission au format CAN (PDF) et en extrait les positions SURLIGNÉES : jaune = fourniture
# seule, autre couleur = fourniture et pose (même convention que l'outil « gestion soumission »).
# Utilise l'API Claude (le PDF est lu visuellement, les surlignages sont donc visibles).
class SoumissionExtractorService
  class ExtractionError < StandardError; end

  MODEL = DevisExtractorService::MODEL

  def initialize(pdf_bytes) = @pdf_bytes = pdf_bytes

  # true si la réponse de l'IA a été coupée (soumission très longue) : seules les positions complètes sont reprises.
  attr_reader :truncated

  # => [{ pos:, designation:, quantity:, unit:, cfc:, chapter:, highlight: "jaune"|"autre" }, ...]
  def extract
    raise ExtractionError, "Clé ANTHROPIC_API_KEY absente de la configuration du serveur." if ENV["ANTHROPIC_API_KEY"].blank?

    response = Anthropic::Client.new.messages.create(
      model: MODEL, max_tokens: 20000,
      output_config: { format_: { schema: schema } },
      messages: [ { role: "user", content: [
        { type: "document", source: { type: "base64", media_type: "application/pdf", data: Base64.strict_encode64(@pdf_bytes) } },
        { type: "text", text: prompt }
      ] } ]
    )
    block = response.content.find { |b| b.type == :text }
    raise ExtractionError, "Réponse vide de l'IA" unless block
    @truncated = response.stop_reason.to_s == "max_tokens"
    parse(block.text)
  rescue Anthropic::Errors::APIError => e
    raise ExtractionError, "Erreur du service d'extraction IA : #{e.message}"
  end

  private

  # Tolère les balises ```json et une réponse coupée (on garde les positions complètes).
  def parse(raw)
    text = raw.to_s.strip.sub(/\A```(?:json)?\s*/, "").sub(/\s*```\z/, "")
    begin
      return (JSON.parse(text, symbolize_names: true)[:items] || [])
    rescue JSON::ParserError
      cut = text.rindex("},")
      if cut
        begin
          items = JSON.parse(text[0..cut] + "]}", symbolize_names: true)[:items] || []
          @truncated = true
          return items
        rescue JSON::ParserError
          nil
        end
      end
    end
    Rails.logger.error("[Soumission] réponse illisible (début) : #{text[0, 300].inspect} … (fin) #{text[-200..].inspect}")
    raise ExtractionError, "Le service d'extraction IA a renvoyé une réponse illisible (réponse trop longue ou mal formée) — essayez avec un extrait du PDF."
  end

  def schema
    item = { type: "object", additionalProperties: false,
             properties: { pos: { type: "string" }, page: { type: "integer" }, designation: { type: "string" }, quantity: { type: [ "number", "null" ] },
                           unit: { type: "string" }, cfc: { type: "string" }, chapter: { type: "string" },
                           highlight: { type: "string", enum: %w[jaune autre] } },
             required: %w[pos page designation quantity unit cfc chapter highlight] }
    { type: "object", properties: { items: { type: "array", items: item } }, required: [ "items" ], additionalProperties: false }
  end

  def prompt
    <<~PROMPT
      Ce document est une soumission de construction (format CAN, descriptif avec positions, quantités et unités).
      Extrait UNIQUEMENT les positions dont le texte est SURLIGNÉ (marqueur fluo), page par page, sans en omettre.
      - page = numéro de la page du PDF (la première page = 1) où figure la position.
      - highlight = "jaune" si le surlignage est jaune (fourniture seule), "autre" pour toute autre couleur (fourniture et pose).
      - pos = numéro de position tel qu'imprimé ; designation = texte de la position (matériau, dimensions, qualité) sans les prix, 200 caractères maximum ;
        quantity / unit = quantité et unité de la position (null si absente) ; cfc = code CFC si visible, sinon "" ;
        chapter = titre du chapitre / sous-chapitre.
      - N'invente rien : un texte illisible ou non surligné n'est pas extrait. Ne recopie AUCUN prix de la soumission.
    PROMPT
  end
end
