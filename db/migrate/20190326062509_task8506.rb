class Task8506 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :check_payment, :boolean, null: false, default: false, after: :status
  end
end
