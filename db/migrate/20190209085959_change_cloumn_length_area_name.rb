class ChangeCloumnLengthAreaName < ActiveRecord::Migration[5.2]
  def change
    change_column :areas, :area_name, :string, limit: 50
  end
end
