# Pièces jointes d'une commande (plans, photos, fiches…), stockées en base comme
# les scans de réception : annexées à l'e-mail envoyé au fournisseur.
class CreateOrderAttachments < ActiveRecord::Migration[8.0]
  def change
    create_table :order_attachments do |t|
      t.integer :order_id, null: false
      t.string  :filename, null: false
      t.string  :content_type, null: false, default: "application/octet-stream"
      t.integer :byte_size, null: false, default: 0
      t.binary  :data, null: false
      t.timestamps
    end
    add_index :order_attachments, :order_id
  end
end
