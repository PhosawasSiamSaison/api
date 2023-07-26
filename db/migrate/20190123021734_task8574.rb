class Task8574 < ActiveRecord::Migration[5.2]
  def change
    # contractor_users
    change_column :contractor_users, :rudy_auth_token, :string, limit: 30

    # contractors
    remove_column :contractors, :latest_credit_limit
    remove_column :contractors, :cashback

    # eligibilities
    add_column :eligibilities, :latest, :boolean, null: false, default: true, after: :class_type
    add_column :eligibilities, :auto_scored, :boolean, null: false, default: false, after: :latest

    # cashback_histories
    rename_column :cashback_histories, :latest_flg, :latest
  end
end
