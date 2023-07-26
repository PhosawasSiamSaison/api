class MailSpoolsChangeColumnNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :mail_spools, :contractor_id, true
    change_column_null :mail_spools, :contractor_user_id, true
  end
end
