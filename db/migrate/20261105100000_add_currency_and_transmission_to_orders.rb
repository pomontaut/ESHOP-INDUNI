# Commande dans une devise étrangère (ex. devis en EUR) : on garde les prix dans la devise d'origine et
# le cours CHF servant à la convertir pour les totaux (Dashboard, Analyse). Commande transmise au
# fournisseur par un autre moyen que l'e-shop : texte libre, affiché à la place de « Envoi ».
class AddCurrencyAndTransmissionToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :currency, :string, default: "CHF", null: false
    add_column :orders, :chf_rate, :decimal, precision: 10, scale: 5
    add_column :orders, :transmitted_via, :string
  end
end
