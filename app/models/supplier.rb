class Supplier < ApplicationRecord
  has_many :products, dependent: :destroy
  has_many :orders, dependent: :destroy

  serialize :visible_cantons, coder: JSON, type: Array
  serialize :visible_sectors, coder: JSON, type: Array

  validates :name, presence: true

  # E-shops en cours de développement : jamais exposés au catalogue hors
  # « Environnement test : Développement » (voir Api::ProductsController).
  # Vide depuis la mise en production de Tinguely et SGTT.
  TEST_ONLY_NAMES = [].freeze

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

  EMAIL_FORMAT = /\A[^@\s,]+@[^@\s,]+\.[^@\s,]+\z/
  # Chaque champ e-mail accepte UNE ou PLUSIEURS adresses, séparées par une
  # virgule, un point-virgule ou un espace ; elles sont normalisées en
  # « a@x.ch, b@x.ch » (dédoublonnées) avant enregistrement.
  EMAIL_COLUMNS = %i[ email email_secondaire email_geneve email_vaud email_valais email_fribourg email_jura ].freeze

  def self.split_emails(text) = text.to_s.split(/[\s,;]+/).reject(&:blank?)

  before_validation :normalize_emails
  EMAIL_COLUMNS.each do |column|
    validate(if: -> { will_save_change_to_attribute?(column) }) do
      bad = self.class.split_emails(self[column]).reject { |e| e.match?(EMAIL_FORMAT) }
      errors.add(column, "contient une adresse invalide : #{bad.join(', ')}") if bad.any?
    end
  end

  # Destinataires d'une commande : adresse principale (ou celle du canton du
  # chantier) + 2e adresse éventuelle, séparées par une virgule.
  def order_emails(canton = nil)
    [ email_for_canton(canton), email_secondaire ].flat_map { |e| self.class.split_emails(e) }.uniq(&:downcase).join(", ").presence
  end

  def email_for_canton(canton)
    column = EMAIL_COLUMN_BY_CANTON[canton]
    (column && public_send(column).presence) || email
  end

  private

  def normalize_emails
    EMAIL_COLUMNS.each do |column|
      self[column] = self.class.split_emails(self[column]).uniq(&:downcase).join(", ").presence
    end
  end
end
