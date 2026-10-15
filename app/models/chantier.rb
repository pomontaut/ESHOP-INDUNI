class Chantier < ApplicationRecord
  validates :nom, presence: true

  # Trois niveaux d'accès possibles à /chantiers (voir User#chantier_access_scope) :
  # admin -> tous les chantiers Induni ; "secteur" -> tous les chantiers du
  # même secteur (BAT GE, GC, etc., voir User::SECTORS) que l'utilisateur ;
  # sinon (défaut) -> uniquement les chantiers où son e-mail est renseigné
  # comme technicien, contremaître ou chef d'équipe.
  # Les chantiers affectés explicitement à l'utilisateur (Admin > Utilisateurs,
  # voir ChantierAssignment) s'ajoutent toujours aux deux premiers niveaux.
  def self.visible_to(user)
    return all if user&.admin?
    return none unless user

    assigned = where(id: ChantierAssignment.where(user_id: user.id).select(:chantier_id))

    if user.chantier_access_scope == "secteur" && user.sector.present?
      return where(secteur: user.sector).or(assigned)
    end

    where(email_technicien: user.email)
      .or(where(email_contremaitre: user.email))
      .or(where(email_chef_equipe: user.email))
      .or(assigned)
  end

  # Chantiers où la personne (prénom + nom saisis à la création du compte)
  # figure comme technicien, contremaître ou chef d'équipe. Comparaison sans
  # accents ni casse, quel que soit l'ordre « Prénom Nom » / « NOM Prénom » :
  # tous les mots du prénom et du nom doivent se retrouver dans le champ.
  ROLE_COLUMNS = { "technicien" => "Technicien", "contremaitre" => "Contremaître", "chef_equipe" => "Chef d'équipe" }.freeze

  def self.matching_person(first_name, last_name)
    wanted = name_tokens("#{first_name} #{last_name}")
    return [] if wanted.size < 2

    all.filter_map do |chantier|
      roles = ROLE_COLUMNS.select do |column, _|
        have = name_tokens(chantier[column])
        have.any? && wanted.all? { |token| have.include?(token) }
      end.values
      { chantier: chantier, roles: roles } if roles.any?
    end
  end

  SEARCH_COLUMNS = %w[
    nom adresse npa ville canton secteur technicien contremaitre chef_equipe conducteur_travaux
    contact_livraison contraintes_acces
  ].freeze

  # Recherche par mots-clés (Admin > Chantiers) : chaque mot saisi doit se
  # retrouver (en début ou à l'intérieur d'un mot, sans accents ni casse) dans
  # le nom, l'adresse, la ville, le NPA ou l'un des contacts du chantier —
  # l'ordre des mots n'a pas d'importance (« vernier halle » = « halle vernier »).
  def self.search(query)
    words = name_tokens(query)
    return order(:nom) if words.empty?

    order(:nom).select do |chantier|
      haystack = name_tokens(SEARCH_COLUMNS.map { |column| chantier[column] }.join(" "))
      words.all? { |word| haystack.any? { |token| token.include?(word) } }
    end
  end

  def self.name_tokens(text)
    I18n.transliterate(text.to_s).downcase.scan(/[a-z0-9]+/)
  end
end
