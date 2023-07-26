class Task8968 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :establish_month, :string, limit: 2, after: :establish_year
  end
end
