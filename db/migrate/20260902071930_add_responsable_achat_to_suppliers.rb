class AddResponsableAchatToSuppliers < ActiveRecord::Migration[8.1]
  def change
    add_column :suppliers, :responsable_achat, :string
  end
end
