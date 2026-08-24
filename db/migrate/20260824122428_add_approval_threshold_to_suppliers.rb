class AddApprovalThresholdToSuppliers < ActiveRecord::Migration[8.1]
  def change
    add_column :suppliers, :approval_threshold, :decimal, precision: 10, scale: 2
  end
end
