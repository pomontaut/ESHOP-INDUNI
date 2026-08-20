class AddEmailSentAtToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :email_sent_at, :datetime
    add_column :orders, :sent_to, :string
    add_column :orders, :sent_cc, :string
    add_column :orders, :sent_subject, :string
    add_column :orders, :sent_body, :text
  end
end
