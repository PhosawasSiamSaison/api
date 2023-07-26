class RenameQuantityToCashbackAmountToCashbackHistories < ActiveRecord::Migration[5.2]
  def change
    rename_column :cashback_histories, :quantity, :cashback_amount
  end
end
