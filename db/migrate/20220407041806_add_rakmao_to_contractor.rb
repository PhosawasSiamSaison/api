class AddRakmaoToContractor < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :is_rakmao, :boolean, null: false, default: false, after: :sub_dealer
  end
end
