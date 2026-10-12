class Order < ApplicationRecord
  belongs_to :supplier
  belongs_to :user, optional: true
  belongs_to :modifies_order, class_name: "Order", optional: true
  # Commande(s) qui remplacent celle-ci (ANNULE ET REMPLACE) — en pratique une
  # seule à la fois, mais has_many au cas où une même commande serait modifiée
  # plusieurs fois (chaque nouvelle version modifie la précédente, pas
  # forcément l'originale).
  has_many :revisions, class_name: "Order", foreign_key: :modifies_order_id, inverse_of: :modifies_order
  has_many :order_lines, dependent: :destroy
  has_many :products, through: :order_lines

  before_create :generate_approval_token
  before_create :generate_reception_token

  def pending_approval? = approval_status == "pending_approval"
  def approved?         = approval_status == "approved"
  def refused?          = approval_status == "refused"
  def reception_confirmed? = reception_confirmed_at.present?
  def cancelled?         = cancelled_at.present?
  def superseded?        = revisions.exists?
  # Une commande annulée, ou remplacée par une version plus récente (ANNULE ET
  # REMPLACE), ne doit plus compter dans les totaux du reporting/dashboard —
  # elle reste néanmoins visible dans l'historique complet, avec une annotation.
  def excluded_from_reporting? = cancelled? || superseded?

  def total
    order_lines.sum(&:subtotal)
  end

  private

  def generate_approval_token
    self.approval_token = SecureRandom.urlsafe_base64(32)
  end

  # Separate from approval_token: this one is handed to the supplier (in the
  # order e-mail) so they can confirm reception, while approval_token is only
  # ever sent to the internal N+1 approver — sharing one token between the two
  # would let a supplier reach the internal approve/refuse pages.
  def generate_reception_token
    self.reception_token = SecureRandom.urlsafe_base64(32)
  end

  before_create :set_number

  # Also used to preview the number a not-yet-created order will get (see
  # Api::OrdersController#next_number), so the "Vérifier et envoyer" step can
  # show/let the user edit the real subject before sending. Racy under
  # concurrent submissions — purely cosmetic if two land at once, since the
  # actual number is still assigned atomically by set_number on save.
  def self.next_number
    last_seq = where("number LIKE 'ESHOP_INDUNI_%'").pluck(:number)
                 .filter_map { |n| n[/\AESHOP_INDUNI_(\d+)\z/, 1]&.to_i }.max || 0
    "ESHOP_INDUNI_#{(last_seq + 1).to_s.rjust(2, '0')}"
  end

  # "ANNULE ET REMPLACE" : la nouvelle commande reprend le numéro de celle
  # qu'elle modifie, suffixé "-V2" (puis "-V3", etc. si modifiée à nouveau) —
  # jamais un nouveau numéro de la séquence générale, pour que le fournisseur
  # reconnaisse immédiatement qu'il s'agit de la même commande corrigée.
  def self.next_version_number(original_order)
    base = original_order.number.to_s.sub(/-V\d+\z/, "")
    versions = where("number LIKE ?", "#{base}-V%").pluck(:number)
                 .filter_map { |n| n[/\A#{Regexp.escape(base)}-V(\d+)\z/, 1]&.to_i }
    "#{base}-V#{(versions.max || 1) + 1}"
  end

  def set_number
    self.number = modifies_order ? self.class.next_version_number(modifies_order) : self.class.next_number
  end
end
