class Chantier < ApplicationRecord
  validates :nom, presence: true

  # Trois niveaux d'accès possibles à /chantiers (voir User#chantier_access_scope) :
  # admin -> tous les chantiers Induni ; "secteur" -> tous les chantiers du
  # même secteur (BAT GE, GC, etc., voir User::SECTORS) que l'utilisateur ;
  # sinon (défaut) -> uniquement les chantiers où son e-mail est renseigné
  # comme technicien, contremaître ou chef d'équipe.
  def self.visible_to(user)
    return all if user&.admin?
    return none unless user

    if user.chantier_access_scope == "secteur" && user.sector.present?
      return where(secteur: user.sector)
    end

    where(email_technicien: user.email)
      .or(where(email_contremaitre: user.email))
      .or(where(email_chef_equipe: user.email))
  end
end
