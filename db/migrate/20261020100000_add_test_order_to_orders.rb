class AddTestOrderToOrders < ActiveRecord::Migration[8.0]
  # Commandes passées depuis l'« Environnement test » (admin) : stockées à part
  # (Dashboard, numérotation ESHOP_TEST_nn) pour ne jamais se mélanger à la
  # production. Les commandes de test déjà envoyées (objet « [TEST] … ») sont
  # reclassées ; celles encore en attente d'approbation n'ont pas d'objet et ne
  # peuvent pas être distinguées.
  def up
    add_column :orders, :test_order, :boolean, default: false, null: false
    execute "UPDATE orders SET test_order = #{connection.quoted_true} WHERE sent_subject LIKE '[TEST]%'"
  end

  def down
    remove_column :orders, :test_order
  end
end
