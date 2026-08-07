class OrderLine < ApplicationRecord
  belongs_to :order
  belongs_to :product

  def subtotal
    quantity.to_i * unit_price.to_f
  end
end
