class AddUserAndApprovalToOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :user, null: true, foreign_key: true
    add_column :orders, :approval_status, :string, default: 'approved'
    add_column :orders, :approver_email,  :string
  end
end
