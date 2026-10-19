class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.string :catalog, null: false
      t.string :article, null: false
      t.string :designation, null: false, default: ""
      t.timestamps
    end
    add_index :favorites, [ :user_id, :catalog, :article, :designation ], unique: true, name: "index_favorites_unique_product"
  end
end
