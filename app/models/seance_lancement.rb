class SeanceLancement < ApplicationRecord
  belongs_to :projet

  validates :budget_cible, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
