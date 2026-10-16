class AddEmailSecondaireToSuppliers < ActiveRecord::Migration[8.0]
  # 2e adresse d'envoi des commandes : le bon de commande part aux deux adresses.
  def change
    add_column :suppliers, :email_secondaire, :string
  end
end
