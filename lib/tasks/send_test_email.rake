desc 'Email送信のテスト'
task :send_test_email, ['mail_address', 'subject', 'message'] => :environment do |task, args|
  mail_address = args[:mail_address]
  subject = args[:subject]
  message = args[:message]

  SendMail.test_mail(mail_address, subject, message)
end
