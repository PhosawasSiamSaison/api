class Task88612 < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :order_one_time_passcode_limit, :integer, default: 15, after: :credit_limit_additional_rate, comment: '分単位'
  end
end
