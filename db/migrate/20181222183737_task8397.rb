class Task8397 < ActiveRecord::Migration[5.2]
  def change
    remove_column :contractors, :owner_bird_ymd, :string
    add_column :contractors, :owner_birth_ymd, :string, limit: 8, after: :owner_sex

    change_column :contractors, :tax_id, :string, limit: 15, null: false
  end
end
