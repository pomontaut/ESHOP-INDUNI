class DieselPrice < ApplicationRecord
  # Base ASTAG "0%" (CHF/litre TVA incl.) à partir de laquelle la surcharge
  # carburant nationale est calculée — voir la note "Basis 0% = CHF 1.64/lit."
  # sur le tableau ASTAG.
  BASE_PRICE = 1.64

  validates :week_start, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  scope :ordered, -> { order(:week_start) }

  def surcharge_pct
    (price.to_f - BASE_PRICE) / BASE_PRICE * 100
  end
end
