class Task8633 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :authorized_person_personal_id, :string, limit: 20, after: :authorized_person_line_id

    add_column :contractors, :contact_person_name,          :string, limit: 20, after: :authorized_person_personal_id
    add_column :contractors, :contact_person_email,         :string, limit: 200, after: :contact_person_name
    add_column :contractors, :contact_person_mobile_number, :string, limit: 15, after: :contact_person_email
    add_column :contractors, :contact_person_line_id,       :string, limit: 20, after: :contact_person_mobile_number
    add_column :contractors, :contact_person_personal_id,   :string, limit: 20, after: :contact_person_line_id
  end
end
