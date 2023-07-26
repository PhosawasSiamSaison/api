# frozen_string_literal: true
# == Schema Information
#
# Table name: business_days
#
#  id                   :bigint(8)        not null, primary key
#  business_ymd         :string(8)        not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class BusinessDay < ApplicationRecord
  default_scope { where(deleted: 0) }

  def today_ymd
    business_ymd
  end

  def today
    Date.parse(today_ymd, ymd_format)
  end

  def tomorrow_ymd
    today.next_day.strftime(ymd_format)
  end

  def yesterday_ymd
    today.prev_day.strftime(ymd_format)
  end

  def tomorrow
    Date.parse(tomorrow_ymd, ymd_format)
  end

  def day_after_tomorrow_ymd
    today.since(2.days).strftime(ymd_format)
  end

  def today_is(day)
    today.day == day
  end

  def is_end_of_month?
    today == today.end_of_month
  end

  def to_ymd date
    date.strftime(ymd_format)
  end

  def to_date ymd
    Date.parse(ymd)
  end

  # 翌日へ更新
  def update_next_day
    update!(business_ymd: tomorrow_ymd)
  end

  def update_ymd!(ymd)
    update!(business_ymd: ymd)
  end

  # 締め日の判定
  def closing_day?(date = today)
    date.day == SystemSetting.closing_day || date.day == date.end_of_month.day
  end

  def closing_ymd?(ymd)
    closing_day?(Date.parse(ymd))
  end

  # 締め日から1ヶ月後の締め日
  def one_month_after_closing_ymd(date = today)
    raise '今日は締め日ではありません' unless closing_day?(date)

    next_month_closing_date =
      if date.day == SystemSetting.closing_day
        date.next_month
      else
        date.next_month.end_of_month
      end

    raise 'next_month_closing_date 算出ロジックが間違っています' unless closing_day?(next_month_closing_date)

    to_ymd(next_month_closing_date)
  end

  def wday_hash
    { sun: 0, mon: 1, tue: 2, wed: 3, thu: 4, fri: 5, stu: 6 }
  end

  # ３営業日前(厳密には違うが)の日付を取得
  # ロジックはチケットのサンプルから算出、
  # Due Dateの前日を起点に、その日を1として2, 3と日付を遡って3っ目を締切日にする
  # 土日の場合はスキップする
  def three_business_days_ago(date)
    wdays = wday_hash()

    # 前日を起点にする
    target_date = date.yesterday

    i = 0
    loop do
      # 土日はカウントをスキップ
      if target_date.wday == wdays[:stu] || target_date.wday == wdays[:sun]
        target_date = target_date.yesterday
        next
      end

      i += 1
      break if i == 3

      target_date = target_date.yesterday
    end

    target_date
  end

  # date + ３営業日 の計算
  def three_business_days_later(date)
    wdays = wday_hash()

    # 翌日を起点にする
    target_date = date.tomorrow

    i = 0
    loop do
      # 土日はカウントをスキップ
      if target_date.wday == wdays[:stu] || target_date.wday == wdays[:sun]
        target_date = target_date.tomorrow
        next
      end

      i += 1
      break if i == 3

      target_date = target_date.tomorrow
    end

    target_date
  end

  # 次の約定日を算出
  def next_due_date(target_date = today)
    if target_date.day <= SystemSetting.closing_day
      # 日を締め日でセットする
      Date.new(target_date.year, target_date.month, SystemSetting.closing_day)
    else
      target_date.end_of_month
    end
  end

  def next_due_ymd(target_date = today)
    due_date = next_due_date(target_date)
    to_ymd(due_date)
  end

  # 業務日が支払い可能範囲の日かの判定
  def in_enable_payment(due_ymd)
    due_date = to_date(due_ymd)

    # DueDateを過ぎていた場合はエラーにする
    raise 'Unexpected Value' if due_date < today

    if due_date.day == SystemSetting.closing_day
      # 15日DueDateなら前月の15日より後(16日以降)なら可能
      prev_month = due_date.prev_month
      Date.new(prev_month.year, prev_month.month, SystemSetting.closing_day) < today
    else
      # 月末のDue Dateなら当月以降なら可能
      due_date.strftime(ym_format) <= today.strftime(ym_format)
    end
  end

  # 業務日以前の一番近い約定日を算出
  def prev_due_ymd
    date =
      # 1~15日
      if today.day <= SystemSetting.closing_day
        # 前月の月末を取得
        today.prev_month.end_of_month
      else
        # 今月の締め日を取得
        Date.new(today.year, today.month, SystemSetting.closing_day)
      end

    to_ymd(date)
  end

  # Set Input Dateの判定（今日までの１ヶ月の間にpurchase_ymdがあるか？）
  def allowed_to_input_date?(purchase_ymd)
    purchase_date = Date.parse(purchase_ymd, ymd_format)

    return false if today < purchase_date

    # 年月が同じならtrueとみなす
    return true if purchase_date.strftime(ym_format) == today.strftime(ym_format)

    # 先月の日が今日の日以上
    (purchase_date.strftime(ym_format) == today.prev_month.strftime(ym_format)) && (purchase_date.day >= today.day)
  end

  # タイ語の月が入った日付形式
  def th_month_format_date(ymd, short_month: false)
    date = Date.parse(ymd)

    year  = date.year
    month = date.month
    day   = date.day

    th_year = year + 543
    th_month = short_month ? th_short_month(month) : th_month(month)

    "#{day} #{th_month} #{th_year}"
  end

  private
    # クラメソッドが呼ばれた場合に、同名のインスタンスメソッドを呼ぶ
    def self.method_missing(method, *args)
      first.send(method, *args)
    end

    def th_month(month)
      {
         1 => 'มกราคม',
         2 => 'กุมภาพันธ์',
         3 => 'มีนาคม',
         4 => 'เมษายน',
         5 => 'พฤษภาคม',
         6 => 'มิถุนายน',
         7 => 'กรกฎาคม',
         8 => 'สิงหาคม',
         9 => 'กันยายน',
        10 => 'ตุลาคม',
        11 => 'พฤศจิกายน',
        12 => 'ธันวาคม',
      }[month]
    end

    def th_short_month(month)
      {
         1 => 'ม.ค.',
         2 => 'ก.พ.',
         3 => 'มี.ค.',
         4 => 'เม.ย.',
         5 => 'พ.ค.',
         6 => 'มิ.ย.',
         7 => 'ก.ค.',
         8 => 'ส.ค.',
         9 => 'ก.ย.',
        10 => 'ต.ค.',
        11 => 'พ.ย.',
        12 => 'ธ.ค.',
      }[month]
    end
end
