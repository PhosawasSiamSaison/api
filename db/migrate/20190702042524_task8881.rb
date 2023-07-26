class Task8881 < ActiveRecord::Migration[5.2]
  def change
    add_column :rudy_api_settings, :bearer, :string, after: :password
  end
end
