class Task9566 < ActiveRecord::Migration[5.2]
  def change
    add_reference :sms_spools, :contractor, foreign_key: true, after: :id
    add_column :sms_spools, :contractor_user_id, :integer, after: :contractor_id
  end
end
