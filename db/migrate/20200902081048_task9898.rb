class Task9898 < ActiveRecord::Migration[5.2]
  def change
    add_reference :sites, :dealer, foreign_key: true, after: :contractor_id
  end
end
