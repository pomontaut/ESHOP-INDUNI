# Appel de livraison : date/heure demandée au fournisseur pour (une partie de)
# une commande. Pour une journée à plusieurs rotations (C4), `slots` porte le
# programme journalier [{ "time" => "07:00", "label" => "Camion 1" }, ...].
class DeliveryCall < ApplicationRecord
  STATUSES = %w[planned delivered cancelled].freeze

  serialize :slots, coder: JSON, type: Array

  belongs_to :order
  belongs_to :user, optional: true
  has_many :lines, class_name: "DeliveryCallLine", dependent: :destroy
  has_many :receptions, dependent: :nullify

  validates :planned_on, presence: true
  validates :status, inclusion: { in: STATUSES }

  def open? = status == "planned"
end
