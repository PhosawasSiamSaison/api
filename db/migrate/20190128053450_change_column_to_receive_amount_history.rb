class ChangeColumnToReceiveAmountHistory < ActiveRecord::Migration[5.2]
  def up
    change_column :receive_amount_histories, :comment, :text
  end

  def down
    change_column :receive_amount_histories, :comment, :string, null: false, limit: 8
  end
end
