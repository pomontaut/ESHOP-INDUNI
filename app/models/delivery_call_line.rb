class DeliveryCallLine < ApplicationRecord
  belongs_to :delivery_call
  belongs_to :order_line

  validates :quantity, numericality: { greater_than: 0 }
end
