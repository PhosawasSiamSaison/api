class Task8488 < ActiveRecord::Migration[5.2]
  def change
    remove_column :contractors, :authorized_person_user_name
  end
end
