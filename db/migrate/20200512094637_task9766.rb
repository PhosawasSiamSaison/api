class Task9766 < ActiveRecord::Migration[5.2]
  def change
    remove_column :contractors, :call_required, :tinyint
  end
end