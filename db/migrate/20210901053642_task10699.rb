class Task10699 < ActiveRecord::Migration[5.2]
  def change
    change_column_null :dealers, :dealer_type, true
    change_column_default :dealers, :dealer_type, from: 1, to: nil

    change_column_null :sites, :dealer_id, false
  end
end
