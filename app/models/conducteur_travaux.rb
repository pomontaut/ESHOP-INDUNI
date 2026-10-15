# Règle métier : Pierre-Olivier Montaut (acheteur/admin) ne doit jamais
# apparaître comme « conducteur de travaux » d'une commande, quelle que soit la
# source (saisie, remplissage automatique du navigateur, fiche chantier).
module ConducteurTravaux
  module_function

  def tokens(name)
    I18n.transliterate(name.to_s).downcase.scan(/[a-z0-9]+/)
  end

  def forbidden?(name)
    t = tokens(name)
    t.include?("montaut") && (%w[pierre olivier po pomontaut].any? { |w| t.include?(w) } || (t.include?("p") && t.include?("o")))
  end

  # Renvoie nil pour le nom interdit (ou vide), sinon le nom nettoyé.
  def sanitize(name)
    name = name.to_s.strip.presence
    name unless name.nil? || forbidden?(name)
  end
end
