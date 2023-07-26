class RemoveRegisteredYmdFromContractor < ActiveRecord::Migration[5.2]
  def change
    remove_column :contractors, :registered_ymd, :string
  end
end
