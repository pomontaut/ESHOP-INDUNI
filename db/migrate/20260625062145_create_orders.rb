class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :number
      t.references :supplier, null: false, foreign_key: true
      t.string :status
      t.text :notes
      t.date :order_date

      t.timestamps
    end
  end
end
