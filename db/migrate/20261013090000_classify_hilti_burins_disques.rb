class ClassifyHiltiBurinsDisques < ActiveRecord::Migration[8.0]
  # Sous-catégories des sous-familles HILTI "Burins" et "Disques", déduites
  # de la désignation (même règle que db/seed_data/catalog_products.json).
  def self.burin(name)
    case name
    when /\AKit/ then "Kit burins"
    when /\AGouge/ then "Gouge brique/béton"
    when /\ABurin à mortier/ then "Burin à mortier"
    when /\ABurin spatule déporté/ then "Burin spatule déporté"
    when /\ABurin pointu/ then "Burin pointu plat"
    when /\ABurin spatule/ then "Burin spatule"
    when /\ABurin plat/ then "Burin plat"
    end
  end

  def self.disque(name)
    modele = if name =~ /\bSPX\b/ then "SPX"
             elsif name =~ /\bSP(-S)?\b/ then "SP"
             elsif name =~ /\bP\b/ then "P"
             end
    if name.start_with?("Kit") then "Kit disques #{modele}"
    elsif name.include?("AC-D") then "Disque à tronçonner"
    elsif name.start_with?("Disque dia", "Disques à tronç.") then "Disque diamant #{modele}"
    end
  end

  def up
    hilti = Supplier.find_by(name: "HILTI")
    return unless hilti

    { "Burins" => :burin, "Disques" => :disque }.each do |sous_famille, rule|
      Product.where(supplier: hilti, sous_famille: sous_famille).find_each do |product|
        categorie = self.class.public_send(rule, product.name.to_s)
        product.update_columns(sous_sous_famille: categorie) if categorie
      end
    end
  end

  def down
    # Non réversible proprement : no-op délibéré.
  end
end
