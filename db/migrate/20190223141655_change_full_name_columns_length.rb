class ChangeFullNameColumnsLength < ActiveRecord::Migration[5.2]
  def change
    change_column :jv_users, :full_name, :string, limit: 40
    change_column :dealer_users, :full_name, :string, limit: 40
    change_column :contractor_users, :full_name, :string, limit: 40
    change_column :contractors, :th_owner_name, :string, limit: 40
    change_column :contractors, :en_owner_name, :string, limit: 40
    change_column :contractors, :authorized_person_full_name, :string, limit: 40
    change_column :contractors, :contact_person_name, :string, limit: 40
  end
end
