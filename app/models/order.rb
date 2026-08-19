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

  def set_number
    last = Order.where("number LIKE 'ESHOP_%'").order(:id).last
    seq = last ? last.number.gsub("ESHOP_", "").to_i + 1 : 1
    self.number = "ESHOP_#{seq.to_s.rjust(2, '0')}"
  end
end
