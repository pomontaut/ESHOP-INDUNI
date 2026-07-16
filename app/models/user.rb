class User < ApplicationRecord
  has_secure_password

  SUPPLIERS = [
    { key: "HGC",        label: "HGC" },
    { key: "Canplast",   label: "Canplast" },
    { key: "Sika",       label: "Sika" },
    { key: "Alzo",       label: "Alzo" },
    { key: "Leuba HIAG", label: "Leuba HIAG SA" }
  ].freeze

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: /\A[^@]+@induni\.ch\z/i, message: "doit être une adresse @induni.ch" }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }
  validates :first_name, :last_name, presence: true, on: :create

  before_save { self.email = email.downcase }

  def full_name
    [first_name, last_name].compact_blank.join(' ').presence || email
  end

  def effective_can_create_users?  = admin? || can_create_users?
  def effective_can_create_orders? = admin? || can_create_orders?
  def effective_can_modify_orders? = admin? || can_modify_orders?
  def effective_can_read?          = admin? || can_read?

  def allowed_suppliers
    return User::SUPPLIERS.map { |s| s[:key] } if admin?
    super || []
  end
end
