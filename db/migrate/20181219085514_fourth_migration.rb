class FourthMigration < ActiveRecord::Migration[5.2]
  def change
    # contractors
    add_column :contractors, :application_number, :string, limit: 20, after: :approval_status

    # info
    drop_table :information
    create_table :infos do |t|
      t.string :title, limit: 20, null: false
      t.text :content
      t.boolean :opened, null: false, default: false
      t.string :open_ymd
      t.string :close_ymd

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    # limit_change_historied
    remove_column :limit_change_histories, :limit_amount, :integer
    add_column :limit_change_histories, :limit_amount, :decimal, after: :contractor_id
    remove_column :limit_change_histories, :update_user_id
    add_column :limit_change_histories, :comment, :string, limit: 30, after: :class_type

    # installments
    drop_table :installments

    # cashback_histories
    drop_table :cashback_history
    create_table :cashback_histories do |t|
      t.integer :contractor_id, null: false
      t.integer :point_type, limit: 1, null: false
      t.integer :quantity, null: false
      t.boolean :latest_flg, null: false
      t.integer :total, null: false
      t.string  :exec_ymd, limit: 8, null: false
      t.string  :notes, limit: 100
      t.integer :order_id
      t.integer :repayment_id

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end
  end
end
