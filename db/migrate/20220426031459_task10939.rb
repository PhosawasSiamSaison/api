class Task10939 < ActiveRecord::Migration[5.2]
  def up
    # test_mailの定数を変更
    MailSpool.where(mail_type: 1).update_all(mail_type: 99)
  end

  def down
    MailSpool.where(mail_type: 99).update_all(mail_type: 1)
  end
end
