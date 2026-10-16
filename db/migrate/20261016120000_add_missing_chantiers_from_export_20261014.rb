class AddMissingChantiersFromExport20261014 < ActiveRecord::Migration[8.0]
  # Export_Chantiers_14102026.csv : 44 chantiers absents de la base (dont 7 en
  # consortium). Aucun doublon : un chantier est considéré comme déjà présent si
  # son nom OU son numéro (partie avant le tiret) existe déjà — dans ce cas on
  # ne crée rien et on ne fait que reporter le statut consortium du fichier.
  # Lignes identiques dans l'export : la dernière a été retenue (voir le JSON).
  # Les « _INACTIF (…) » des techniciens/contremaîtres ont été retirés.
  # Ville et canton ne figurent pas dans l'export : à compléter en admin.
  DATA_PATH = Rails.root.join("db/seed_data/chantiers_nouveaux_20261014.json")

  def up
    JSON.parse(File.read(DATA_PATH)).each do |attrs|
      number = attrs["nom"][/\A(\d{4,6})-/, 1]
      existing = Chantier.where("LOWER(nom) = ?", attrs["nom"].downcase)
      existing = existing.or(Chantier.where("nom LIKE ?", "#{number}-%")) if number

      if existing.exists?
        existing.where.not(consortium: attrs["consortium"]).update_all(consortium: attrs["consortium"])
      else
        Chantier.create!(attrs)
      end
    end
  end

  def down
    # Non réversible : no-op délibéré (des chantiers ont pu être utilisés depuis).
  end
end
