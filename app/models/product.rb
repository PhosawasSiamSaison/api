# frozen_string_literal: true
# == Schema Information
#
# Table name: products
#
#  id                      :bigint(8)        not null, primary key
#  product_key             :integer
#  product_name            :string(40)
#  switch_sms_product_name :string(255)
#  number_of_installments  :integer
#  sort_number             :integer
#  annual_interest_rate    :decimal(5, 2)
#  monthly_interest_rate   :decimal(5, 2)
#  deleted                 :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  operation_updated_at    :datetime
#  lock_version            :integer          default(0)
#

class Product < ApplicationRecord
  default_scope { where(deleted: 0) }

  # 商品追加の手順(db:migrateとdb:resetの両方に対応させる)
  # seedに商品を追加する
  # マイグレーションで商品を生成する(seedで入っていれば作成しない判定を入れる)

  validates :product_key, uniqueness: { case_sensitive: false }

  # 商品変更を設定できる対象商品(1以外をリストへ表示)
  scope :available_change, -> { where.not(product_key: [1]) }
  scope :number_sort, -> { order(:sort_number) }

  class << self
    # Reschedule Product
    def reschedule_product(count, no_interest)
      return nil if count.blank?

      interest_rate = no_interest ? 0.0 : RescheduleOrderInterestList.new.get_interest(count)

      new(
        number_of_installments: count.to_i,
        annual_interest_rate: interest_rate,
        monthly_interest_rate: 0.0,
      )
    end

    # Fee Product
    def fee_product(count)
      return nil if count.blank?

      new(
        number_of_installments: count.to_i,
        annual_interest_rate: 0.0,
        monthly_interest_rate: 0.0,
      )
    end

    # sort_numberの一括更新
    def update_sort_numbers(product_keys)
      transaction do
        all.count.times.each{|i|
          product_key = product_keys[i]

          find_by(product_key: product_key)&.update!(sort_number: i + 1)
        }
      end
    end
  end

  # 1回分の支払い金額
  def installment_amount(amount, interest_rate = nil)
    # 支払いが1回の場合はtotal_amountを返す(分割計算をすると、余の分が引かれるので)
    if number_of_installments == 1
      total_amount(amount, interest_rate)
    else
      # 1回分の元本
      installment_principal = one_installment_amount(amount)

      # 1回分の利子
      installment_interest = one_installment_amount(interest(amount, interest_rate))

      # 利子と元本を足す
      (installment_principal + installment_interest).round(2).to_f
    end
  end

  # 支払う合計
  def total_amount(amount, interest_rate = nil)
    # 元本の合計
    total_principal = total_installment_amount(amount)

    # 利子の合計
    total_interest = total_installment_amount(interest(amount, interest_rate))

    # 利子と元本を足す
    (total_principal + total_interest).round(2).to_f
  end

  # 分割番号を指定して、１回分の支払い金額を算出
  def installment_amount_by_number(installment_number, amount, interest_rate = nil)
    if installment_number == 1
      installment_amount(amount, interest) + amari(amount)
    else
      installment_amount(amount, interest)
    end
  end

  def installment_amounts(amount, interest_rate = nil)
    # 以下の形式を返す
    #
    # {
    #   installments: {
    #     1 => { principal: 1001, interest: 25, total: 1025 },
    #     2 => { principal: 1000, interest: 25, total: 1025 },
    #     3 => { principal: 1000, interest: 25, total: 1025 },
    #   },
    #   total_installment: { principal: 3001, interest: 75, total_amount: 3071 },
    # }

    installments = {}

    # pp "::: interest_rate = #{interest_rate}"
    total_interest = interest(amount, interest_rate)

    number_of_installments.times.each.with_index(1) {|hoge, installment_number|
      installment_principal = one_installment_amount(amount)
      installment_interest = one_installment_amount(total_interest)

      if installment_number == 1
        installment_principal += amari(amount)
        installment_interest += amari(total_interest)
      end

      installments[installment_number] = {
        principal: installment_principal.round(2).to_f,
        interest: installment_interest.round(2).to_f,
        total: (installment_principal + installment_interest).round(2).to_f
      }
    }

    total_installment = {
      principal: amount.to_f,
      interest: total_interest.to_f,
      total_amount: (amount + total_interest).round(2).to_f
    }

    { installments: installments, total_installment: total_installment }
  end

  # RUDY-API Get Installment Info の install_amounts 算出用メソッド
  def rudy_install_amounts(amount, interest_rate = nil)
    amounts = []
    installment_amounts_data = installment_amounts(amount, interest_rate)[:installments]

    number_of_installments.times.each.with_index(1) do |_, installment_number|
      amounts.push(installment_amounts_data[installment_number][:total])
    end

    amounts
  end

  # installment_numberと約定日のデータを返す({ 1 => '20190101', ... })
  def calc_due_ymds(target_ymd)
    # 返却用の変数
    due_ymds = {}

    target_date = Date.parse(target_ymd, ymd_format)

    # TODO 日数の取得。実装後にカラムから取得する
    term_days =
      case product_key
      when 8
        15
      when 1, 2, 3, 11
        30
      when 4, 5, 6, 9
        60
      when 7, 10, 12, 13
        90
      else # ในกรณีที่มีการต่อสัญญา ฯลฯ
        30
      end

    # 約定日の前まで進める月日を算出する
    advance_day = term_days % 30   # 日: 0 / 15
    advance_month = term_days / 30 # 月: 0 / 1 / 2 / 3

    # 約定日の前まで月を進める
    advanced_date = target_date + advance_month.month

    # 最初の約定日を算出する
    first_due_date =
      if advance_day == 15
        if (1..15).include?(advanced_date.day)
          # 月末
          advanced_date.end_of_month
        else
          # 翌月の15日
          next_month = advanced_date.next_month
          Date.new(next_month.year, next_month.month, SystemSetting.closing_day)
        end
      else
        if (1..15).include?(advanced_date.day)
          # 15日
          Date.new(advanced_date.year, advanced_date.month, SystemSetting.closing_day)
        else
          # 月末
          advanced_date.end_of_month
        end
      end

    # 分割回数分のデータを作成
    number_of_installments.times.each do |i|
      # 締め日が15日
      if first_due_date.day <= SystemSetting.closing_day
        # 直近の締め日を取得
        nearest_closing_date =
          Date.new(first_due_date.year, first_due_date.month, SystemSetting.closing_day)

        # 締め日を基準に１カ月ずつ日付を進めて取得
        due_date = nearest_closing_date + i.month

      # 締め日が月末
      else
        # 次の月の月末を取得していく
        due_date = (first_due_date + i.month).end_of_month
      end

      # 1から始まるkeyで格納する
      due_ymds[i + 1] = due_date.strftime(ymd_format)
    end

    due_ymds
  end

  private
  # 余りの算出
  def amari(amount)
    # これ以上分割が出来ない値は、余りを出せないので0で返す
    if amount < 0.03
      0
    else
      # 分割金額をタイバーツの小数点金額にするために、余りを1/100の金額にする
      ((amount * 100.0).round(2) % number_of_installments / 100.0).round(2)
    end
  end

  # 利息の算出
  def interest(amount, interest_rate = nil)
    interest_rate ||= annual_interest_rate.to_f
    (BigDecimal(amount.to_s) * interest_rate * 0.01).round(2).to_f
  end

  # 1回目の分割金額
  def first_installment_amount(amount)
    (one_installment_amount(amount) + amari(amount)).round(2).to_f
  end

  # 2回目以降の分割金額の合計
  def after_second_total_installment_amount(amount)
    (one_installment_amount(amount) * (number_of_installments - 1)).round(2).to_f
  end

  # 1回分の分割金額(元本、利子の計算用)
  def one_installment_amount(amount)
    # これ以上分割が出来ない値は、分割金額を出せないのでamountをそのまま返す
    if (amount - amari(amount)) < 0.03
      amount
    else
      # 分割回数で割り切れる値にしてから分割回数で割る
      # number_of_installmentsを100で悪と、0.03 / 0.03 で 1になってしまう
      ((amount - amari(amount)).round(2) / number_of_installments).round(2).to_f
    end
  end

  # 合計の分割金額(元本、利子の計算用)
  def total_installment_amount(amount)
    # 1回目と2回目以降の分割金額を足す
    (first_installment_amount(amount) + after_second_total_installment_amount(amount)).round(2).to_f
  end
end
