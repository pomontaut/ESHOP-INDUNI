class AddPrixExterneToProducts < ActiveRecord::Migration[8.1]
  # Second tarif optionnel (prix de vente externe) utilisé par le catalogue
  # "Matériel Induni" (dépôt interne) : le prix interne (unit_price) reste
  # celui utilisé pour la commande/le panier, prix_externe n'est qu'une
  # référence affichée en plus sur la fiche article — voir prix_m2 pour le
  # même principe (référentiel affiché, pas utilisé dans les calculs).
  def change
    add_column :products, :prix_externe, :decimal
  end
end
