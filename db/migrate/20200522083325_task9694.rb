class Task9694 < ActiveRecord::Migration[5.2]
  def up
    remove_column :contractors, :dealer_type

    create_table :applied_dealers do |t|
      t.references :contractor, foreign_key: true
      t.references :dealer, foreign_key: true
      t.integer    :sort_number, limit: 1, null: false
      t.string     :applied_ymd, limit: 8, null: false

      t.timestamps
      t.datetime   :operation_updated_at
      t.integer    :lock_version, default: 0
    end
    add_index :applied_dealers, [:contractor_id, :dealer_id], name: 'ix_1', unique: true

    create_table :dealer_type_limits do |t|
      t.references :eligibility, foreign_key: true
      t.integer    :dealer_type, limit: 1, null: false, default: 1
      t.decimal    :limit_amount, precision: 10, scale: 2, null: false

      t.integer    :deleted, limit: 1, null: false, default: 0
      t.timestamps
      t.datetime   :operation_updated_at
      t.integer    :lock_version, default: 0
    end
    add_index :dealer_type_limits, [:eligibility_id, :dealer_type], name: 'ix_1', unique: true


    create_table :dealer_limits do |t|
      t.references :eligibility, foreign_key: true
      t.references :dealer, foreign_key: true
      t.decimal    :limit_amount, precision: 10, scale: 2, null: false

      t.integer    :deleted, limit: 1, null: false, default: 0
      t.timestamps
      t.datetime   :operation_updated_at
      t.integer    :lock_version, default: 0
    end
    add_index :dealer_limits, [:eligibility_id, :dealer_id], name: 'ix_1', unique: true


    create_table :terms_of_service_versions do |t|
      t.references :contractor_user, foreign_key: true
      t.integer    :dealer_type, limit: 1, null: true
      t.boolean    :sub_dealer, null: false, default: false

      t.timestamps
      t.datetime   :operation_updated_at
      t.integer    :lock_version, default: 0
    end
    add_index :terms_of_service_versions, [:contractor_user_id, :dealer_type, :sub_dealer], name: 'ix_1', unique: true
  end

  def down
    drop_table :terms_of_service_versions
    drop_table :dealer_limits
    drop_table :dealer_type_limits
    drop_table :applied_dealers
    add_column :contractors, :dealer_type, :integer, limit: 1, null: false, default: 1, after: :sub_dealer
  end
end
