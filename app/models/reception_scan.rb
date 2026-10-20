# Scan / photo d'un bon de livraison, stocké en base (pas de dépendance à un
# disque persistant). Le navigateur réduit les photos avant envoi.
class ReceptionScan < ApplicationRecord
  CONTENT_TYPES = %w[image/jpeg image/png image/webp application/pdf].freeze
  MAX_BYTES = 8 * 1024 * 1024

  belongs_to :reception

  validates :content_type, inclusion: { in: CONTENT_TYPES, message: "non accepté (JPEG, PNG, WebP ou PDF)" }
  validates :byte_size, numericality: { less_than_or_equal_to: MAX_BYTES, message: "dépasse 8 Mo" }
  validates :data, presence: true
end
