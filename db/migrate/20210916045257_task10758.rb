class Task10758 < ActiveRecord::Migration[5.2]
  def change
    change_column_null :dealers, :dealer_type, false

    add_column :dealers, :for_normal_rate, :decimal, precision: 5, scale: 2, default: 2,
      null: false, after: :dealer_code, comment: 'for Transaction Fee'

    add_column :dealers, :for_government_rate, :decimal, precision: 5, scale: 2, default: 1.75,
      null: true, after: :for_normal_rate, comment: 'for Transaction Fee'

    add_column :dealers, :for_sub_dealer_rate, :decimal, precision: 5, scale: 2, default: 1.5,
      null: true, after: :for_government_rate, comment: 'for Transaction Fee'
  end
end
