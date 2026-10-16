class AddPickupToOrders < ActiveRecord::Migration[8.0]
  # « Enlèvement dépôt » (HG COMMERCIALE) : Induni récupère la commande au
  # dépôt du fournisseur, aucune livraison ni frais de transport.
  def change
    add_column :orders, :pickup, :boolean, default: false, null: false
  end
end
