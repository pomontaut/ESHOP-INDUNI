class CreateReceptionsAndDeliveryCalls < ActiveRecord::Migration[8.1]
  # Module « Réception de commande et appel de livraison » (environnement test).
  # La commande d'achat est celle de l'e-shop (pas d'ABACUS) ; on ajoute dessus :
  #  - le type de gestion (C1…C5) et la date de facturation,
  #  - les appels de livraison (planification, rotations d'une journée),
  #  - les réceptions physiques (une par bon de livraison / camion) avec scans de BL.
  # Pas de clé étrangère SQL : la purge des commandes (Admin > Commandes) fait des
  # delete_all et nettoie ces tables elle-même.
  def change
    add_column :orders, :reception_type, :string
    add_column :orders, :invoiced_at, :datetime

    create_table :delivery_calls do |t|
      t.references :order, null: false, foreign_key: false
      t.references :user, foreign_key: false
      t.date :planned_on, null: false
      t.string :planned_time
      t.string :status, null: false, default: "planned"
      t.text :notes
      t.text :slots
      t.timestamps
    end

    create_table :delivery_call_lines do |t|
      t.references :delivery_call, null: false, foreign_key: false
      t.references :order_line, null: false, foreign_key: false
      t.decimal :quantity, precision: 14, scale: 3, null: false, default: 0
      t.timestamps
    end

    create_table :receptions do |t|
      t.references :order, null: false, foreign_key: false
      t.references :delivery_call, foreign_key: false
      t.references :user, foreign_key: false
      t.date :received_on, null: false
      t.string :bl_number
      t.string :status, null: false, default: "accepte"
      t.decimal :progress_percent, precision: 6, scale: 2
      t.text :comment
      t.timestamps
    end

    create_table :reception_lines do |t|
      t.references :reception, null: false, foreign_key: false
      t.references :order_line, null: false, foreign_key: false
      t.decimal :quantity_received, precision: 14, scale: 3, null: false, default: 0
      t.decimal :quantity_accepted, precision: 14, scale: 3, null: false, default: 0
      t.timestamps
    end

    create_table :reception_scans do |t|
      t.references :reception, null: false, foreign_key: false
      t.string :filename
      t.string :content_type, null: false
      t.integer :byte_size, null: false, default: 0
      t.binary :data, null: false
      t.timestamps
    end
  end
end
