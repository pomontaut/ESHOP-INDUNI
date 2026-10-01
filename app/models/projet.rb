class Projet < ApplicationRecord
  STATUTS = { "en_cours" => "En cours", "clos" => "Clos" }.freeze

  belongs_to :chantier, optional: true
  belongs_to :responsable, class_name: "User", optional: true
  has_one :seance_lancement, dependent: :destroy

  validates :nom, presence: true
  validates :statut, inclusion: { in: STATUTS.keys }

  scope :en_cours, -> { where(statut: "en_cours") }

  def statut_label = STATUTS.fetch(statut)

  # La séance de lancement est créée à la demande (une seule par projet).
  def seance_lancement_or_build
    seance_lancement || build_seance_lancement
  end
end
