class Task10660 < ActiveRecord::Migration[5.2]
  def change
    add_column :dealers, :en_dealer_name, :string, limit: 50, :after => :dealer_name
  end
end
