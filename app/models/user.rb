class User < ApplicationRecord
  has_secure_password
  serialize :allowed_suppliers, coder: JSON, type: Array
  has_many :push_subscriptions, dependent: :destroy

  SECTORS = [
    "BAT GE", "BAT VD", "GC", "EG VS", "EG VD", "EG GE", "DEPOT",
    "ADMIN GE", "ADMIN VS", "ADMIN VD", "TRANSFO GE", "TRANSFO VD"
  ].freeze

  SUPPLIERS = [
    { key: "HGC",        label: "HGC" },
    { key: "Canplast",   label: "Canplast" },
    { key: "Leuba HIAG", label: "Leuba HIAG SA" },
    { key: "CreaBeton",  label: "CreaBeton" },
    { key: "MBT",        label: "MBT" },
    { key: "ALZO AG",    label: "ALZO AG" },
    { key: "Soreval",    label: "Soreval" },
    { key: "BTest",      label: "BTest" },
    { key: "LCBE",       label: "LCBE" }
  ].freeze

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: /\A[^@]+@induni\.ch\z/i, message: "doit être une adresse @induni.ch" }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }
  validates :first_name, :last_name, presence: true, on: :create

  before_save { self.email = email.downcase }

  # Garantie permanente : ce compte reste administrateur même si la
  # synchronisation au démarrage (BOOTSTRAP_ADMIN_EMAIL) ou la colonne
  # `admin` en base venait à diverger.
  PERMANENT_ADMIN_EMAILS = [ "pomontaut@induni.ch" ].freeze

  def admin?
    super || PERMANENT_ADMIN_EMAILS.include?(email&.downcase)
  end

  def full_name
    [ first_name, last_name ].compact_blank.join(" ").presence || email
  end

  def effective_can_create_users?  = admin? || can_create_users?
  def effective_can_create_orders? = admin? || can_create_orders?
  def effective_can_modify_orders? = admin? || can_modify_orders?
  def effective_can_read?          = admin? || can_read?
  def effective_can_import_quote?  = admin? || can_import_quote?
  def effective_can_generic_order? = admin? || can_generic_order?
  def effective_can_view_dashboard?    = admin? || can_view_dashboard?
  def effective_can_view_analysis?     = admin? || can_view_analysis?
  def effective_can_view_nomenclature? = admin? || can_view_nomenclature?

  def allowed_suppliers
    return User::SUPPLIERS.map { |s| s[:key] } if admin?
    super || []
  end

  # Combines the manual per-user override above (allowed_suppliers) with the
  # per-supplier "quels secteurs voient ce contrat" rules configured in
  # /admin/fournisseurs — kept as a separate method (not folded into
  # allowed_suppliers) so the admin user-edit checkboxes keep reflecting the
  # raw manual override, not this computed result.
  def effective_visible_suppliers
    return Supplier.pluck(:name) if admin?
    sector_allowed = Supplier.all.select { |s| s.visible_for_sector?(sector) }.map(&:name)
    manual = allowed_suppliers
    manual.empty? ? sector_allowed : (sector_allowed & manual)
  end
end
