class RemoveEstablishYmdFromContractor < ActiveRecord::Migration[5.2]
  def change
    remove_column :contractors, :establish_ymd, :string
  end
end
