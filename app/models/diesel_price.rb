class DieselPrice < ApplicationRecord
  # Base ASTAG "0%" (CHF/litre TVA incl.) — voir la note "Basis 0% = CHF
  # 1.64/lit." sur le tableau ASTAG.
  BASE_PRICE = 1.64

  # Barème officiel ASTAG (colonnes de droite du tableau "Dieselpreise") —
  # ce n'est PAS une fonction linéaire simple de (prix - base) / base : le
  # premier palier (0% → ±1%) ne vaut que la moitié du pas des paliers
  # suivants (+0.045 CHF au lieu de +0.09 CHF). Impossible à reproduire par
  # une formule unique, d'où cette interpolation point par point du barème
  # tel que publié.
  SURCHARGE_SCALE = [
    [ 1.235, -5.0 ], [ 1.325, -4.0 ], [ 1.415, -3.0 ], [ 1.505, -2.0 ], [ 1.595, -1.0 ],
    [ 1.64,   0.0 ], [ 1.685,  1.0 ], [ 1.775,  2.0 ], [ 1.865,  3.0 ], [ 1.955,  4.0 ],
    [ 2.045,  5.0 ], [ 2.135,  6.0 ], [ 2.225,  7.0 ], [ 2.315,  8.0 ], [ 2.405,  9.0 ]
  ].freeze

  validates :week_start, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  scope :ordered, -> { order(:week_start) }

  # Interpole le barème ASTAG pour un prix CHF/litre donné, en extrapolant
  # au même pas que le dernier segment connu au-delà de ses bornes.
  def self.pct_for_price(chf)
    table = SURCHARGE_SCALE
    if chf <= table.first[0]
      (x0, y0), (x1, y1) = table[0], table[1]
    elsif chf >= table.last[0]
      (x0, y0), (x1, y1) = table[-2], table[-1]
    else
      (x0, y0), (x1, y1) = table.each_cons(2).find { |(a, _), (b, _)| chf >= a && chf <= b }
    end
    y0 + (chf - x0) / (x1 - x0) * (y1 - y0)
  end

  def surcharge_pct
    self.class.pct_for_price(price.to_f)
  end
end
