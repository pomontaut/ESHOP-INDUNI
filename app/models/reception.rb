# Réception physique : un bon de livraison, un camion ou un événement de
# livraison (ou, pour une prestation C5, une validation d'avancement).
class Reception < ApplicationRecord
  STATUSES = %w[accepte reserves refuse].freeze
  MAX_SCANS = 10

  belongs_to :order
  belongs_to :delivery_call, optional: true
  belongs_to :user, optional: true
  has_many :lines, class_name: "ReceptionLine", dependent: :destroy
  has_many :scans, class_name: "ReceptionScan", dependent: :destroy

  validates :received_on, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :progress_percent, numericality: { in: 0..100 }, allow_nil: true
end
