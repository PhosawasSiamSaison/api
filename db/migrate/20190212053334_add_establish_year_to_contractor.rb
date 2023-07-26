class AddEstablishYearToContractor < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :establish_year, :string, limit: 4, after: :establish_ymd
  end
end
