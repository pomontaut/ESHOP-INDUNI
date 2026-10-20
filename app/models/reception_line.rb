class ReceptionLine < ApplicationRecord
  belongs_to :reception
  belongs_to :order_line

  validates :quantity_received, :quantity_accepted, numericality: { greater_than_or_equal_to: 0 }
  validate :accepted_not_above_received

  private

  def accepted_not_above_received
    errors.add(:quantity_accepted, "ne peut pas dépasser la quantité livrée") if quantity_accepted.to_d > quantity_received.to_d
  end
end
