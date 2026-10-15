class ChantierAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :chantier

  validates :chantier_id, uniqueness: { scope: :user_id }
end
