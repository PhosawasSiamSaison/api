class Task9275 < ActiveRecord::Migration[5.2]
  def change
    # business_days
    drop_table :infos
    drop_table :dealers_infos
    drop_table :confirm_works
  end
end
