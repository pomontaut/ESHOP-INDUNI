class CanplastSurcharge < ApplicationRecord
  validates :codes, :label, :effective_date, presence: true
  validates :surcharge_pct, presence: true, numericality: true

  scope :ordered, -> { order(:codes, :effective_date) }

  # Un groupe d'articles = une combinaison (codes, label) — ex. "A1, A2, A3"
  # pour "tuyaux de canalisation et de drainage PVC compact".
  def self.groups
    ordered.pluck(:codes, :label).uniq
  end

  def self.timeline_for(codes)
    where(codes: codes).order(:effective_date)
  end
end
