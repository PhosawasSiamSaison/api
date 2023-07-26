module DealerPaymentModule
   # 税率
  VAT_RATE = 1.07

  def calc_purchase_amount
    if second_dealer.blank?
      purchase_amount
    elsif !is_second_dealer
      first_dealer_amount
    else
      second_dealer_amount
    end
  end

  # VATを除いた購入金額
  def purchase_amount_without_vat
    if second_dealer.blank?
      # RUDYからの入力値があれば保存したカラムの値を使用する
      return amount_without_tax.to_f if amount_without_tax.present?

      # なければ購入額から算出する
      calc_without_vat(purchase_amount)
    elsif !is_second_dealer
      calc_without_vat(first_dealer_amount)
    else
      calc_without_vat(second_dealer_amount)
    end
  end

  def calc_without_vat(amount)
    (amount / VAT_RATE).round(2).to_f
  end

  def vat_amount
    (calc_purchase_amount - purchase_amount_without_vat).round(2).to_f
  end

  def transaction_fee_rate
    # Dealer TypeとContractorの属性で割合を分岐する
    rate =
      if contractor.normal?
        dealer.for_normal_rate
      elsif contractor.government?
        dealer.for_government_rate
      elsif contractor.sub_dealer?
        dealer.for_sub_dealer_rate
      elsif contractor.individual?
        dealer.for_individual_rate
      end

    (rate / 100)
  end

  # Transaction Fee
  def transaction_fee
    # input_ymdが2022-01-01以降は vat_amountを含む金額(購入金額)で計算する
    amount = input_ymd >= '20220101' ? calc_purchase_amount : purchase_amount_without_vat

    (BigDecimal(amount.to_s) * transaction_fee_rate).round(2)
  end

  # transaction_feeの7%
  def value_added_tax
    (transaction_fee * 0.07).round(2).to_f
  end

  # transaction_feeの3%
  def withholding_tax
    (transaction_fee * 0.03).round(2).to_f
  end

  def invoice_amount
    (transaction_fee + value_added_tax - withholding_tax).round(2).to_f
  end

  def dealer_payment_amount
    (calc_purchase_amount - invoice_amount).round(2).to_f
  end
end
