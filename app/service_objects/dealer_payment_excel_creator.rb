class DealerPaymentExcelCreator
  require 'rubyXL'
  require 'rubyXL/convenience_methods/cell'
  require 'rubyXL/convenience_methods/color'
  require 'rubyXL/convenience_methods/font'
  require 'rubyXL/convenience_methods/workbook'
  require 'rubyXL/convenience_methods/worksheet'

  def call(dealer, input_ymd, orders)
    # テンプレートの読み込み
    file_path =
      if dealer.cpac_group?
        Rails.root.join('lib/templates/dealer_payment_cpac.xlsx')
      else
        Rails.root.join('lib/templates/dealer_payment.xlsx')
      end

    workbook = RubyXL::Parser.parse(file_path)

    @work_sheet = workbook.first
    @work_sheet.sheet_name = "#{dealer.dealer_code}_#{input_ymd}"

    # Dealer情報
    add_cell(3, :b, dealer.dealer_name)

    address_ary = dealer.address&.split(/\r\n|\r|\n/) || []
    add_cell(4, :b, address_ary[0])
    add_cell(5, :b, address_ary[1])
    add_cell(6, :b, address_ary[2])
    add_cell(7, :b, address_ary[3])
    add_cell(8, :b, address_ary[4])

    change_contents(11, :b, "วันที่สรุปยอดรายการ: #{th_date(input_ymd)}")

    change_contents(13, :n, transferring_date(input_ymd))
    change_contents(66, :n, transferring_date(input_ymd))

    # transaction fee の %を設定
    transaction_fee_rate = orders.first.transaction_fee_rate
    change_contents(17, :s, transaction_fee_rate)
    change_contents(55, :e, transaction_fee_rate)

    # Order情報
    orders.each.with_index(1) do |order, index|
      # 31行以降は枠外に表示する
      base_row_index = index <= 30 ? 18 : 40 # 31行以降は70行から
      row_num = base_row_index + index - 1

      if dealer.cpac_group?
        change_contents(row_num, :b, index)
        change_contents(row_num, :c, order.order_number)
        change_contents(row_num, :d, order.order_type)
        change_contents(row_num, :e, order.region)
        change_contents(row_num, :f, order.contractor.th_company_name)
        change_contents(row_num, :j, order.any_site.site_code)
        change_contents(row_num, :l, order.purchase_amount_without_vat)
        change_contents(row_num, :m, order.vat_amount)
        change_contents(row_num, :p, order.calc_purchase_amount)
        change_contents(row_num, :r, order.installment_count)
        change_contents(row_num, :s, order.transaction_fee)
      else
        change_contents(row_num, :b, index)
        change_contents(row_num, :c, order.order_number)
        change_contents(row_num, :e, order.contractor.th_company_name)
        change_contents(row_num, :j, order.purchase_amount_without_vat)
        change_contents(row_num, :l, order.vat_amount)
        change_contents(row_num, :p, order.calc_purchase_amount)
        change_contents(row_num, :r, order.installment_count)
        change_contents(row_num, :s, order.transaction_fee)
      end
    end

    total_calc_purchase_amount = total_calc_purchase_amount(orders)

    # オーダー合計
    change_contents(49, :j, total_purchase_amount_without_vat(orders))
    change_contents(49, :p, total_calc_purchase_amount)

    # 手数料のトータル
    total_transaction_fee = total_transaction_fee(orders)

    # 下記の値は手数料のトータルから計算する
    total_value_added_tax = (total_transaction_fee * 0.07).round(2)
    total_withholding_tax = (total_transaction_fee * 0.03).round(2)
    total_invoice_amount = (total_transaction_fee + total_value_added_tax - total_withholding_tax).round(2)
    total_dealer_payment_amount = (total_calc_purchase_amount - total_invoice_amount).round(2)

    change_contents(49, :s, total_transaction_fee)

    # ◆ (A) ยอดเรียกเก็บผู้แทนจำหน่าย (โดย บ. สยามเซย์ซอน)
    # Total
    change_contents(53, :g, total_invoice_amount)
    # n%
    change_contents(55, :g, total_transaction_fee)
    # 7%
    change_contents(56, :g, total_value_added_tax)
    # 3%
    change_contents(57, :g, total_withholding_tax)

    # ◆ (B) ยอดชำระตามรายการธุรกรรม (ก่อนหักค่าบริการ)
    change_contents(53, :o, total_calc_purchase_amount)

    # Bank Account
    change_contents(55, :k, dealer.bank_account)

    # ◆◆ ยอดสุทธิ (ยอดชำระหักค่าบริการ) ชำระโดย บ.สยามเซย์ซอน ให้ผู้แทนจำหน่าย (B-A)
    change_contents(65, :o, total_dealer_payment_amount)

    # 印刷範囲の設定
    workbook.defined_names.first.reference = "#{@work_sheet.sheet_name}!$B$1:$Q$68"

    # 出力
    workbook
  end

  private

  def col(key)
    {
      a: 0, b: 1, c: 2, d: 3, e: 4, f: 5, g: 6, h: 7, i: 8, j: 9, k: 10, l:11, m: 12, n: 13,
      o: 14, p: 15, q: 16, r: 17, s: 18, t: 19, u: 20, v: 21
    }[key]
  end

  def add_cell(row_num, col_key, content)
    @work_sheet.add_cell(row_num - 1, col(col_key), content)
  end

  def change_contents(row_num, col_key, content)
    @work_sheet[row_num - 1][col(col_key)].change_contents(content)
  end

  def total_purchase_amount_without_vat(orders)
    orders.sum(&:purchase_amount_without_vat).round(2)
  end

  def total_transaction_fee(orders)
    orders.sum(&:transaction_fee).round(2)
  end

  def total_calc_purchase_amount(orders)
    orders.sum(&:calc_purchase_amount).round(2)
  end

  def transferring_date(input_ymd)
    date = Date.parse(input_ymd)

    ymd = BusinessDay.to_ymd(BusinessDay.three_business_days_later(date))

    th_date(ymd)
  end

  def th_date(ymd)
    BusinessDay.th_month_format_date(ymd)
  end
end