class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :reference
      t.decimal :unit_price
      t.references :supplier, null: false, foreign_key: true

      t.timestamps
    end
  end
end
