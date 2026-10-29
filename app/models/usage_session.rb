# Une ouverture de l'e-shop (onglet) d'un utilisateur suivi — voir UsageReport.
class UsageSession < ApplicationRecord
  has_many :usage_events, dependent: :delete_all
end
