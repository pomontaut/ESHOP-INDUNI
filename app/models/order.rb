class Order < ApplicationRecord
  belongs_to :supplier
  has_many :order_lines, dependent: :destroy
  has_many :products, through: :order_lines

  before_create :set_number

  def total
    order_lines.sum(&:subtotal)
  end

  private

  def set_number
    last = Order.where("number LIKE 'ESHOP_%'").order(:id).last
    seq = last ? last.number.gsub('ESHOP_', '').to_i + 1 : 1
    self.number = "ESHOP_#{seq.to_s.rjust(2, '0')}"
  end
end
