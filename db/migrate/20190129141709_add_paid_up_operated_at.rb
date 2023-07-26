class AddPaidUpOperatedAt < ActiveRecord::Migration[5.2]
  def change
    add_column :payments, :paid_up_operated_ymd, :string, limit: 8, after: :paid_up_ymd
  end
end
