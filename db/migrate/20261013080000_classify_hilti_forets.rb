class ClassifyHiltiForets < ActiveRecord::Migration[8.0]
  # Les 40 forets HILTI (sous-famille "Forets") sont répartis en 4
  # sous-catégories, déduites du début de la désignation.
  RULES = [
    ["Hammer drill bit",   "Mèche de perceuse à percussion métrique (Hammer drill bit)"],
    ["Mèche pour coffrage", "Mèche pour coffrage"],
    ["Mèche spirale",      "Mèche spirale"],
    ["Mèche de forage",    "Mèche de forage"]
  ].freeze

  def up
    hilti = Supplier.find_by(name: "HILTI")
    return unless hilti

    RULES.each do |prefix, categorie|
      Product.where(supplier: hilti, sous_famille: "Forets")
             .where("name LIKE ?", "#{prefix}%")
             .update_all(sous_sous_famille: categorie)
    end
  end

  def down
    # Non réversible proprement : no-op délibéré.
  end
end
