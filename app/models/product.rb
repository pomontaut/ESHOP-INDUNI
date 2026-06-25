class Product < ApplicationRecord
  belongs_to :supplier
  validates :name, :reference, :unit_price, presence: true
end
