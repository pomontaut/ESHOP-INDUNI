# Les briques du portail achat (voir le schéma "Portail achat"). Chaque brique
# existe au niveau global ET au niveau d'un projet en cours : le portail traite
# les projets de façon individualisée, avec le même jeu de briques.
# `url` / `projet_url` : lambdas (nil => brique pas encore construite).
module PortailAchat
  Brique = Struct.new(:key, :label, :icone, :description, :url, :projet_url, keyword_init: true) do
    def disponible? = url.present? || projet_url.present?
  end

  def self.briques(helpers)
    soumission = ENV["SOUMISSION_URL"].presence
    [
      Brique.new(key: "lancement", label: "Séance de lancement achat", icone: "🚀",
                 description: "Cadrage achat d'un projet : périmètre, budget cible, stratégie, risques, décisions.",
                 url: nil, projet_url: ->(p) { helpers.projet_seance_lancement_path(p) }),
      Brique.new(key: "eshop", label: "E-shop", icone: "🛒",
                 description: "Catalogues fournisseurs et commandes.",
                 url: "/catalogue.html", projet_url: ->(_p) { "/catalogue.html" }),
      Brique.new(key: "soumission", label: "Soumission", icone: "📄",
                 description: "Demandes de prix et suivi des offres par lot.",
                 url: soumission, projet_url: soumission && ->(_p) { soumission }),
      Brique.new(key: "evaluation", label: "Évaluation fournisseur", icone: "⭐",
                 description: "Notation et suivi de la performance des fournisseurs."),
      Brique.new(key: "contratheque", label: "Contrathèque", icone: "📑",
                 description: "Contrats et accords cadre."),
      Brique.new(key: "spend", label: "Spend analyse", icone: "📊",
                 description: "Analyse des dépenses d'achat."),
      Brique.new(key: "base_fournisseurs", label: "Base fournisseurs", icone: "🏭",
                 description: "Référentiel des fournisseurs.", url: helpers.suppliers_path),
      Brique.new(key: "indicateurs", label: "Indicateurs achats", icone: "📈",
                 description: "Tableaux de bord et KPI achats."),
      Brique.new(key: "bibliotheque_prix", label: "Bibliothèque de prix", icone: "💰",
                 description: "Prix de référence par article.")
    ]
  end
end
