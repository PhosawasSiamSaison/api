class Task11075 < ActiveRecord::Migration[5.2]
  def up
    create_table :send_email_addresses do |t|
      t.references :mail_spool, null: false
      t.references :contractor_user, null: true
      t.string :send_to

      t.timestamps
      t.datetime :operation_updated_at
    end

    # 新しいテーブルにmail_spools.send_toのデータを移行する
    MailSpool.all.each do |mail_spool|
      # 複数の宛先を分割する
      mail_spool.send_to.split(',').each do |send_to|
        # 新しいテーブルデータを作成する
        SendEmailAddress.create!(
          mail_spool: mail_spool,
          contractor_user_id: mail_spool.contractor_user_id,
          send_to: send_to.strip
        )
      end
    end

    remove_column :mail_spools, :send_to, :text
    remove_column :mail_spools, :contractor_user_id, :integer
  end

  def down
    add_column :mail_spools, :contractor_user_id, :integer, after: :contractor_id
    add_column :mail_spools, :send_to, :text, after: :contractor_user_id

    # データを戻す
    MailSpool.all.each do |mail_spool|
      mail_spool.update!(
        contractor_user_id: mail_spool.send_email_addresses.first.contractor_user_id,
        send_to: mail_spool.email_addresses_str
      )
    end

    drop_table :send_email_addresses
  end
end
