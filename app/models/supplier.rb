class Supplier < ApplicationRecord
  has_many :products, dependent: :destroy
  has_many :orders, dependent: :destroy

  validates :name, presence: true
end
