class CreateReceiveHistoryTable < ActiveRecord::Migration[5.2]
  def change
    create_table :project_receive_amount_histories do |t|
      t.references :contractor, foreign_key: true, null: false
      t.references :project_phase_site, foreign_key: true, null: false
      t.string :receive_ymd, limit: 8, null: false
      t.decimal :receive_amount, precision: 10, scale: 2, null: false
      t.decimal :exemption_late_charge, precision: 10, scale: 2
      t.text :comment
      t.references :create_user, foreign_key: { to_table: :jv_users }, null: false, class: JvUser

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.datetime :operation_updated_at
      t.integer :lock_version, default: 0
    end

    add_column :contractors, :project_exemption_late_charge_count, :integer, limit: 2,
      null: false, default: 0, after: :exemption_late_charge_count
  end
end
