class ReorganizeHiltiSubFamilles < ActiveRecord::Migration[8.0]
  # Réorganisation demandée des sous-familles HILTI du dépôt INDUNI, en 5
  # dossiers regroupant les 14 sous-familles existantes : Burins, Disques,
  # Forets (incl. mèches hélicoïdales), Lame, Meules boisseaux.
  MAPPING = {
    "Burins TE-C" => "Burins",
    "Burins TE-S" => "Burins",
    "Burins TE-Y" => "Burins",
    "Burins standards" => "Burins",

    "Disques à tronçonner abrasifs" => "Disques",
    "Disques à tronçonner diamantés" => "Disques",

    "Forets TE-CX" => "Forets",
    "Forets TE-YX" => "Forets",
    "Forets creux TE-C" => "Forets",
    "Forets creux TE-Y" => "Forets",
    "Forets pour coffrage TE-C" => "Forets",
    "Mèches hélicoïdales" => "Forets",

    "Lames de scie sabre" => "Lame",

    "Meules boisseaux diamantées" => "Meules boisseaux"
  }.freeze

  def up
    hilti = Supplier.find_by(name: "HILTI")
    return unless hilti

    MAPPING.each do |old_value, new_value|
      Product.where(supplier: hilti, sous_famille: old_value).update_all(sous_famille: new_value)
    end
  end

  def down
    # Non réversible proprement (fusion plusieurs->un) : no-op délibéré.
  end
end
