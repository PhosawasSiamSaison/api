class Task11073 < ActiveRecord::Migration[5.2]
  def up
    change_column :mail_spools, :send_to, :text
  end

  def down
    change_column :mail_spools, :send_to, :string
  end
end
