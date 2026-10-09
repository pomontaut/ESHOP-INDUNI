class ReorganizeEfcoSubFamilles < ActiveRecord::Migration[8.0]
  # Réorganisation demandée des sous-familles EFCO du dépôt INDUNI :
  #  1. Fusionne les deux dossiers "accessoires aspirateur" (orthographes
  #     différentes du même dossier).
  #  2. Nouveau dossier "Visserie" : clous Spike/Spit, toutes les catégories
  #     de vis, les tiges (d'ancrage et filetées).
  #  3. Nouveau dossier "Consommable machine à outil" : burinage, disques,
  #     embout visseuse, lames, mèches.
  #  4. Nouveau dossier "Quincaillerie" : rondelles, boulons, douilles,
  #     écrous.
  MAPPING = {
    "Accesoires aspirateur" => "Accessoires aspirateur",
    "Accessoire aspirateur" => "Accessoires aspirateur",

    "Clou Spike" => "Visserie",
    "Clou Spit" => "Visserie",
    "Vis à cadres" => "Visserie",
    "Vis à béton" => "Visserie",
    "Vis à bois" => "Visserie",
    "Vis autoforeuse" => "Visserie",
    "Vis à béton d'isolation" => "Visserie",
    "Tige d'ancrage" => "Visserie",
    "Tige filetée" => "Visserie",

    "Burinage" => "Consommable machine à outil",
    "Disque isolation" => "Consommable machine à outil",
    "Disques diamantés" => "Consommable machine à outil",
    "Disque fer" => "Consommable machine à outil",
    "Embout visseuse" => "Consommable machine à outil",
    "Lame outils multifonctions" => "Consommable machine à outil",
    "Lame scie sauteuse" => "Consommable machine à outil",
    "Lame scie sabre" => "Consommable machine à outil",
    "Mèche bois" => "Consommable machine à outil",
    "Mèche béton" => "Consommable machine à outil",
    "Mèches feraille" => "Consommable machine à outil",
    "Mèche carrelage" => "Consommable machine à outil",

    "Rondelle" => "Quincaillerie",
    "Boulon" => "Quincaillerie",
    "Douille" => "Quincaillerie",
    "Ecrous" => "Quincaillerie"
  }.freeze

  def up
    efco = Supplier.find_by(name: "EFCO")
    return unless efco

    MAPPING.each do |old_value, new_value|
      Product.where(supplier: efco, sous_famille: old_value).update_all(sous_famille: new_value)
    end
  end

  def down
    # Non réversible proprement (fusion plusieurs->un) : no-op délibéré.
  end
end
