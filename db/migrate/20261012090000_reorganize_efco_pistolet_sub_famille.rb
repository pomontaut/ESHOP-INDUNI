class ReorganizeEfcoPistoletSubFamille < ActiveRecord::Migration[8.0]
  # Fusionne les 3 petits dossiers EFCO "Pistolet résine", "Pistolet mousse"
  # et "Pistolet Spit" (2+2+1 articles) en un seul dossier "Pistolet".
  MAPPING = {
    "Pistolet résine" => "Pistolet",
    "Pistolet mousse" => "Pistolet",
    "Pistolet Spit" => "Pistolet"
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
