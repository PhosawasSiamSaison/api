class Task110652 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :enable_rudy_confirm_payment, :boolean, default: true, after: :register_user_id
  end
end
