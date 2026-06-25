class Order < ApplicationRecord
  belongs_to :supplier
  has_many :order_lines, dependent: :destroy
  has_many :products, through: :order_lines

  STATUSES = %w[draft sent confirmed received].freeze

  before_create :set_number

  validates :status, inclusion: { in: STATUSES }
  validates :order_date, presence: true

  def total
    order_lines.sum { |line| line.quantity * line.unit_price }
  end

  private

  def set_number
    self.number ||= "CMD-#{Time.now.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end
end
