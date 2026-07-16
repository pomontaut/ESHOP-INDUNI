class AddApprovalTokenAndCommentToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :approval_token, :string
    add_column :orders, :approval_comment, :text
  end
end
