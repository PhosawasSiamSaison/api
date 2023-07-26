class Task10877 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :delay_penalty_rate, :integer, limit: 2, null: false, default: 18,
      after: :pool_amount, comment: "遅損金の率。整数で保持する"
  end
end
