# Mémoire de l'agent « chiffreur soumission » : désignation de soumission ↔ article du catalogue.
class SoumissionMatch < ApplicationRecord
  STATUSES = %w[confirmed rejected].freeze
  validates :norm_designation, :supplier_name, :product_reference, presence: true
  validates :status, inclusion: { in: STATUSES }

  def self.norm(text) = SearchMemory.norm(text)

  # Enregistre (ou renforce) un jugement de l'utilisateur sur un rapprochement.
  def self.learn!(designation:, product:, status:, user: nil)
    m = find_or_initialize_by(norm_designation: norm(designation), supplier_name: product.supplier.name, product_reference: product.reference)
    m.designation = designation.to_s.truncate(300)
    m.user_id = user&.id
    m.uses = m.new_record? ? 1 : m.uses + 1
    m.status = status
    m.save!
    m
  end
end
