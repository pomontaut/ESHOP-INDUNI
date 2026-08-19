class Order < ApplicationRecord
  belongs_to :supplier
  belongs_to :user, optional: true
  belongs_to :modifies_order, class_name: "Order", optional: true
  has_many :order_lines, dependent: :destroy
  has_many :products, through: :order_lines

  before_create :generate_approval_token

  def pending_approval? = approval_status == "pending_approval"
  def approved?         = approval_status == "approved"
  def refused?          = approval_status == "refused"

  def total
    order_lines.sum(&:subtotal)
  end

  private

  def generate_approval_token
    self.approval_token = SecureRandom.urlsafe_base64(32)
  end

  before_create :set_number

  # Also used to preview the number a not-yet-created order will get (see
  # Api::OrdersController#next_number), so the "Vérifier et envoyer" step can
  # show/let the user edit the real subject before sending. Racy under
  # concurrent submissions — purely cosmetic if two land at once, since the
  # actual number is still assigned atomically by set_number on save.
  def self.next_number
    last = where("number LIKE 'ESHOP_%'").order(:id).last
    seq = last ? last.number.gsub("ESHOP_", "").to_i + 1 : 1
    "ESHOP_#{seq.to_s.rjust(2, '0')}"
  end

  def set_number
    self.number = self.class.next_number
  end
end
