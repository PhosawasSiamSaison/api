class SecondMigration < ActiveRecord::Migration[5.2]
  def change
    # dealers
    add_column :dealers, :dealer_key, :string, limit: 7, after: :id
    add_column :dealers, :address, :string, limit: 100, after: :phone_number

    # contractors
    add_column :contractors, :performance, :integer, limit: 1, after: :business_history
    remove_column :contractors, :approval_user_id, :integer
    add_column :contractors, :approval_user_id, :integer, after: :rejected

    # point_histories
    drop_table :point_history
    create_table :point_histories do |t|
      t.integer :contractor_id, null: false
      t.integer :point_type, limit: 1, null: false
      t.integer :quantity, null: false
      t.boolean :latest_flg, null: false
      t.integer :total, null: false
      t.string  :exec_ymd, limit: 8, null: false
      t.string  :notes, limit: 100
      t.integer :transaction_id
      t.integer :installment_id
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    # limit_change_history
    drop_table :limit_change_history
    create_table :limit_change_histories do |t|
      t.integer :contractor_id, null: false
      t.integer :limit_amount, null: false
      t.integer :update_user_id, null: false
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    # contractor_users
    add_column :contractor_users, :sex, :integer, limit: 1, after: :user_name
    add_column :contractor_users, :birth_ymd, :string, limit: 8, after: :sex
  end
end
