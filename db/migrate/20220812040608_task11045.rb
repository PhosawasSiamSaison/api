class Task11045 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractor_users, :verify_mode, :integer, limit: 1, null: false, default: 1, after: :initialize_token
    add_column :contractor_users, :verify_mode_otp, :string, limit: 10, null: true, after: :verify_mode
  end
end
