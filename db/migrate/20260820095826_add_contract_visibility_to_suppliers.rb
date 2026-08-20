class AddContractVisibilityToSuppliers < ActiveRecord::Migration[8.1]
  def change
    add_column :suppliers, :visible_cantons, :text
    add_column :suppliers, :visible_sectors, :text
    add_column :suppliers, :email_geneve, :string
    add_column :suppliers, :email_vaud, :string
    add_column :suppliers, :email_valais, :string
    add_column :suppliers, :email_fribourg, :string
    add_column :suppliers, :email_jura, :string
  end
end
