# Pièce jointe saisie par l'utilisateur à la validation du panier (glisser-déposer
# ou sélection de fichier) ; annexée à l'e-mail de commande envoyé au fournisseur.
class OrderAttachment < ApplicationRecord
  MAX_FILE_BYTES  = 8 * 1024 * 1024
  MAX_TOTAL_BYTES = 15 * 1024 * 1024
  MAX_FILES       = 10
  BLOCKED_EXT     = %w[exe bat cmd com scr js vbs msi dll jar ps1 sh].freeze

  belongs_to :order

  validates :filename, :data, presence: true
  validates :byte_size, numericality: { less_than_or_equal_to: MAX_FILE_BYTES, message: "dépasse 8 Mo" }
  validate :extension_allowed

  def self.safe_filename(name)
    File.basename(name.to_s).gsub(/[^\w.\- ()àâäçéèêëîïôöùûüÀÉÈ]/, "_").strip.presence || "piece_jointe"
  end

  private

  def extension_allowed
    ext = File.extname(filename.to_s).delete(".").downcase
    errors.add(:filename, "type de fichier non accepté (#{ext})") if BLOCKED_EXT.include?(ext)
  end
end
