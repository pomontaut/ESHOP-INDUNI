class Supplier < ApplicationRecord
  has_many :products, dependent: :destroy
  has_many :orders, dependent: :destroy

  serialize :visible_cantons, coder: JSON, type: Array
  serialize :visible_sectors, coder: JSON, type: Array

  validates :name, presence: true

  CANTONS = [ "GENEVE", "VAUD", "VALAIS", "FRIBOURG", "JURA" ].freeze
  SECTORS = [ "GC", "BAT GE", "BAT VD", "TRANSFO GE", "TRANSFO VD" ].freeze

  # Acheteur en charge du contrôle des nouveaux articles de ce fournisseur
  # (voir Api::NomenclatureController) — assigné automatiquement à chaque
  # article importé d'un devis sans catégorie connue.
  BUYERS = [ "Nina Heider", "Emilie Baranski", "Pierre-Olivier Montaut", "Aurélien Dondelet", "Nicolas Guéry" ].freeze

  # An empty list means "no restriction configured" — visible everywhere /
  # to everyone, same convention as User#allowed_suppliers, so a supplier
  # nobody has configured yet keeps behaving exactly as before.
  def visible_for_canton?(canton)
    return true if canton.blank?
    list = visible_cantons || []
    list.empty? || list.include?(canton)
  end

  def visible_for_sector?(sector)
    return true if sector.blank?
    list = visible_sectors || []
    list.empty? || list.include?(sector)
  end

  EMAIL_COLUMN_BY_CANTON = {
    "GENEVE"   => :email_geneve,
    "VAUD"     => :email_vaud,
    "VALAIS"   => :email_valais,
    "FRIBOURG" => :email_fribourg,
    "JURA"     => :email_jura
  }.freeze

  def email_for_canton(canton)
    column = EMAIL_COLUMN_BY_CANTON[canton]
    (column && public_send(column).presence) || email
  end
end
