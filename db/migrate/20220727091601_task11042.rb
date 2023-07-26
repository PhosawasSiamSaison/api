class Task11042 < ActiveRecord::Migration[5.2]
  def change
    add_reference :mail_spools, :contractor_billing_data, foreign_key: true, after: :mail_type
  end
end
