class CreateOrderNumberFloors < ActiveRecord::Migration[8.0]
  # Plancher de numérotation (ESHOP_INDUNI_nn) : après avoir vidé les commandes
  # (Admin > Commandes), la séquence continue au lieu de repartir à 01, pour ne
  # jamais réattribuer à un fournisseur un numéro qu'il a déjà reçu.
  def change
    create_table :order_number_floors do |t|
      t.integer :floor, null: false, default: 0
      t.timestamps
    end
  end
end
