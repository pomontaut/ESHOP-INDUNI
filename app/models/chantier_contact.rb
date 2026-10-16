# Personne supplémentaire d'un chantier, en plus de la personne principale
# saisie dans les colonnes de Chantier (technicien, contremaître, chef d'équipe,
# contact réception livraison) : utile sur les gros chantiers.
class ChantierContact < ApplicationRecord
  belongs_to :chantier

  # Rôles qui donnent accès au chantier via leur e-mail (voir Chantier.visible_to).
  ACCESS_ROLES = %w[technicien contremaitre chef_equipe].freeze
  ROLES = (ACCESS_ROLES + [ "contact_livraison" ]).freeze

  validates :role, inclusion: { in: ROLES }
  validates :nom, presence: true

  before_validation do
    self.nom   = nom.to_s.strip.presence
    self.natel = natel.to_s.strip.presence
    self.email = email.to_s.strip.downcase.presence
  end
end
