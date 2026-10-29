# Événement d'usage (agent d'usage, administrateur seulement). Jamais de prix ni de contenu de commande.
class UsageEvent < ApplicationRecord
  belongs_to :usage_session, optional: true

  KINDS = %w[login visit click nav search add_to_cart].freeze
  VIAS  = %w[recherche liste image].freeze

  validates :kind, inclusion: { in: KINDS }

  def payload
    @payload ||= (data.present? ? JSON.parse(data) : {})
  rescue JSON::ParserError
    {}
  end

  # Connexion explicite (écran de login).
  def self.record_login!(user)
    return unless user.usage_tracked?

    create!(user_id: user.id, kind: "login", occurred_at: Time.current)
  end
end
