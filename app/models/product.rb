class Product < ApplicationRecord
  belongs_to :supplier
  has_many :price_changes, class_name: "ProductPriceChange", dependent: :delete_all

  # Les anciennes migrations créent des produits avant l'existence de la table
  # d'historique : le callback ne s'applique qu'une fois la table créée.
  after_save :record_price_change, if: -> { saved_change_to_unit_price? && !unit_price.nil? && ProductPriceChange.table_exists? }

  validates :name, presence: true
  validates :reference, presence: true

  private

  def record_price_change
    price_changes.create!(price: unit_price, changed_at: Time.current)
  end
end
