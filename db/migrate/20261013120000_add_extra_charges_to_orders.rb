class AddExtraChargesToOrders < ActiveRecord::Migration[8.0]
  def change
    # Frais annexes (transport, RPLP, grue, remise de volume, etc.) calculés
    # côté client au moment de l'envoi (voir transportDetailsInduni dans
    # catalogue.html) : sérialisés ici en JSON ([{label:, amount:}, ...]) pour
    # être repris tels quels par le bon de commande PDF, au lieu d'être
    # recalculés (et potentiellement désynchronisés) côté serveur.
    add_column :orders, :extra_charges, :text
  end
end
