class Task8421 < ActiveRecord::Migration[5.2]
  def change
    # contractor
    add_column :contractors, :owner_user_name, :string, limit: 20, after: :capital_fund_mil
    change_column :contractors, :main_dealer_id, :integer, null: true
    remove_column :contractors, :owner_user_name
    add_column :contractors, :call_required, :boolean, null: false, default: false, after: :status
    remove_column :contractors, :applied_ymd
    add_column :contractors, :applied_date, :datetime, after: :application_number
    add_column :contractors, :authorized_person_user_name, :string, limit: 20, after: :owner_email
    add_column :contractors, :authorized_person_full_name, :string, limit: 20, after: :authorized_person_user_name
    add_column :contractors, :authorized_person_title_division, :string, limit: 20, after: :authorized_person_full_name
    add_column :contractors, :authorized_person_mobile_number, :string, limit: 15, after: :authorized_person_title_division
    add_column :contractors, :authorized_person_line_id, :string, limit: 20, after: :authorized_person_mobile_number

    # contractor user
    remove_column :contractor_users, :personal_id
    remove_column :contractor_users, :email

    # dealer
    remove_column :dealers, :registered_ymd

    # installments
    drop_table :repayments
    create_table :installments do |t|
      t.integer :order_id, null: false
      t.integer :installment_number, limit: 1, null: false
      t.string  :installment_schedule_ymd, limit: 8, null: false
      t.decimal :installment_schedule_amount, null: false
      t.string  :paid_ymd, limit: 8
      t.decimal :paid_amount
      t.boolean :delayed
      t.decimal :delay_installment_amount
      t.boolean :jv_checked, null: false, default: false
      t.boolean :batch_checked, null: false, default: false
      t.boolean :last_installment, null: false, default: false

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end
  end
end
