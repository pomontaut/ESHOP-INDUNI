class AddSectorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :sector, :string
  end
end
