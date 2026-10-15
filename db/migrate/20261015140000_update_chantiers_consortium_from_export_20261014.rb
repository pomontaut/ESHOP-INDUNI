class UpdateChantiersConsortiumFromExport20261014 < ActiveRecord::Migration[8.0]
  # Mise à jour du statut « chantier consortium » depuis l'export
  # Export_Chantiers_14102026.csv. Ne modifie QUE la colonne consortium, par
  # nom de chantier exact (toutes les lignes portant ce nom) : aucun chantier
  # créé ni supprimé, aucun autre champ touché.
  DATA_PATH = Rails.root.join("db/seed_data/chantiers_consortium_20261014.json")

  def up
    statuses = JSON.parse(File.read(DATA_PATH))
    statuses.each do |nom, consortium|
      Chantier.where(nom: nom).where.not(consortium: consortium).update_all(consortium: consortium)
    end
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
