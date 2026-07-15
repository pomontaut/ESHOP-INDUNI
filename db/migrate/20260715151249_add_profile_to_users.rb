class AddProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :job_function, :string
    add_column :users, :must_change_password, :boolean, default: false, null: false
  end
end
