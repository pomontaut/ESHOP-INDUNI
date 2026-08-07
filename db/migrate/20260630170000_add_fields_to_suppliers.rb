class AddFieldsToSuppliers < ActiveRecord::Migration[8.1]
  def change
    add_column :suppliers, :supplier_number, :string
    add_column :suppliers, :fax, :string
    add_column :suppliers, :city, :string
    add_column :suppliers, :postal_code, :string
    add_column :suppliers, :country_code, :string
    add_column :suppliers, :ide_number, :string
    add_column :suppliers, :payment_condition, :string
    add_column :suppliers, :inactive, :boolean, default: false
    change_column_null :suppliers, :email, true
  end
end
