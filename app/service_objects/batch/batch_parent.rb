class Batch::BatchParent
  def self.delay_batch_send_sms
    # AWS は １秒間に20件まで
    # LINE は１分間に2000件までのレート制限
    JvService::Application.config.try(:delay_batch_send_sms)
  end

  private
  def self.print_info str
    # テスト環境では邪魔なので出さない様にする
    puts str unless Rails.env.test?
  end
end
