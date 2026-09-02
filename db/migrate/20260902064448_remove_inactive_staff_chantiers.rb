class RemoveInactiveStaffChantiers < ActiveRecord::Migration[8.1]
  # Nettoyage ponctuel demandé par l'utilisateur : certains chantiers listent
  # un technicien/contremaître/chef d'équipe marqué "_INACTIF (...)" — la
  # personne a quitté l'entreprise mais le chantier n'a jamais été retiré de
  # la liste. On supprime entièrement ces lignes (pas seulement le contact).
  def up
    fields = %i[technicien contremaitre chef_equipe]
    ids = Chantier.pluck(:id, *fields).select { |_id, *values| values.any? { |v| v&.include?("_INACTIF") } }.map(&:first)
    Chantier.where(id: ids).delete_all
  end

  def down
    # Correction de données uniquement — pas de retour arrière possible.
  end
end
