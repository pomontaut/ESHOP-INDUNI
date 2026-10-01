class DedupeChantiersByExactName < ActiveRecord::Migration[8.1]
  MERGEABLE_ATTRS = %w[
    adresse canton carte_interactive chef_equipe conducteur_travaux
    contraintes_acces contremaitre email_chef_equipe email_conducteur_travaux
    email_contremaitre email_technicien natel_chef_equipe natel_conducteur_travaux
    natel_contremaitre natel_technicien npa secteur technicien ville
  ].freeze

  # De nombreux chantiers existent en base sous plusieurs lignes partageant
  # exactement le même nom (une ligne par combinaison technicien/
  # contremaître/chef d'équipe, probablement un artefact de l'import
  # d'origine) — jusqu'à 10 lignes pour "12501-Caran d'Ache". Deux chantiers
  # peuvent en revanche partager le même numéro de tête avec un nom
  # différent (ex. "35605-Esplanade des Vernets" et
  # "35605-Renaturation La Plaine" : deux projets distincts) — on ne
  # fusionne donc que sur le nom exact, jamais sur le seul numéro.
  #
  # Pour chaque groupe de doublons : on garde la ligne la plus ancienne
  # (id le plus bas), on complète ses champs vides avec la première valeur
  # non vide trouvée parmi les doublons, puis on supprime les doublons
  # (Order ne référence un chantier que par son nom en texte libre dans
  # notes, jamais par une clé étrangère — aucun risque de casser une
  # commande existante).
  #
  # Si les doublons d'un même nom ne sont pas d'accord sur "consortium"
  # (certains vrai, d'autres faux), on ne peut pas trancher automatiquement
  # sans risquer de sous-facturer un chantier consortium : on force
  # consortium à true (le sens le moins coûteux à se tromper) et on marque
  # consortium_conflict pour que l'admin le vérifie — visible comme un badge
  # sur /admin/chantiers.
  def up
    add_column :chantiers, :consortium_conflict, :boolean, default: false, null: false

    conflicts = []

    duplicate_noms = Chantier.group(:nom).having("count(*) > 1").pluck(:nom)
    duplicate_noms.each do |nom|
      rows = Chantier.where(nom: nom).order(:id).to_a
      keeper = rows.first
      donors = rows.drop(1)

      updates = {}
      MERGEABLE_ATTRS.each do |attr|
        next if keeper[attr].present?
        donor = donors.find { |d| d[attr].present? }
        updates[attr] = donor[attr] if donor
      end

      if rows.map(&:consortium).uniq.size > 1
        conflicts << nom
        updates["consortium"] = true
        updates["consortium_conflict"] = true
      end

      keeper.update_columns(updates) if updates.present?
      donors.each(&:destroy)
    end

    if conflicts.any?
      Rails.logger.warn(
        "[DedupeChantiersByExactName] Statut consortium incohérent entre doublons pour : " \
        "#{conflicts.join(', ')} — forcé à consortium=true, consortium_conflict=true posé " \
        "pour vérification admin (voir /admin/chantiers)."
      )
    end
  end

  def down
    # Fusion/suppression de données uniquement — les doublons supprimés
    # sont perdus, aucun retour arrière possible.
    remove_column :chantiers, :consortium_conflict
  end
end
