class Task11040 < ActiveRecord::Migration[5.2]
  def change
    change_column_default :payments, :status, from: nil, to: 1
  end
end
