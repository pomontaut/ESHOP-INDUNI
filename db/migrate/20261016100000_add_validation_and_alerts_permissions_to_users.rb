class AddValidationAndAlertsPermissionsToUsers < ActiveRecord::Migration[8.0]
  # Droits d'affichage de deux boutons du bandeau e-shop. Par défaut vrai :
  # tous les comptes existants gardent leur interface actuelle, un admin peut
  # ensuite les retirer compte par compte (Admin > Droits).
  def change
    add_column :users, :can_validate_orders, :boolean, default: true, null: false
    add_column :users, :can_enable_alerts, :boolean, default: true, null: false
  end
end
