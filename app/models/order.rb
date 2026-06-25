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
    self.number = "CMD-#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end
end
