class CheckCalculateController < ApplicationController
  
  def check_over_dealer_limit
		tax_id               = params[:tax_id]
    order_number         = params[:order_number]
    product_key          = params[:product_id]
    dealer_code          = params[:dealer_code]
    rudy_purchase_ymd    = params[:purchase_date]
    purchase_amount      = params[:amount].to_f
    amount_without_tax   = params[:amount_without_tax]
    second_dealer_code   = params[:second_dealer_code]
    second_dealer_amount = params[:second_dealer_amount].to_f
    region               = params[:region]
    auth_token           = params[:auth_token]

    contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
    contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
		subtraction_amount = 0
		# ContractorUserチェック
		contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
		contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
		raise(ValidationError, 'unverified') if auth_token.blank? || contractor_user.blank?

		# Dealerチェック
		dealer = Dealer.find_by(dealer_code: dealer_code)
		raise(ValidationError, 'unmatch_dealer_type') if dealer.site_dealer?

    # return false if use_only_credit_limit

    dealer_limit_amount = contractor.dealer_limit_amount(dealer)
    dealer_remaining_principal = contractor.dealer_remaining_principal(dealer)

    expanded_credit_limit_amount =
      BigDecimal(dealer_limit_amount.to_s) * SystemSetting.credit_limit_additional_rate

    # recreateの場合は現在購入金額を引く
    remaining_principal = dealer_remaining_principal - subtraction_amount

    # 利用可能限度枠から残りの返済額を引く(マイナスは0にする)
    dealer_available_balance =
      [(expanded_credit_limit_amount - remaining_principal).round(2), 0].max

    dealer_available_balance < purchase_amount

    render json: {
			purchase_amount: purchase_amount,
			dealer_limit_amount: dealer_limit_amount,
			dealer_remaining_principal: dealer_remaining_principal,
			credit_limit_additional_rate: SystemSetting.credit_limit_additional_rate,
			expanded_credit_limit_amount: expanded_credit_limit_amount,
			remaining_principal: remaining_principal,
			dealer_available_balance: dealer_available_balance,
			validate_failed: dealer_available_balance < purchase_amount,
		}
  end

	def check_dealer_remaining_principal
		tax_id               = params[:tax_id]
    order_number         = params[:order_number]
    product_key          = params[:product_id]
    dealer_code          = params[:dealer_code]
    rudy_purchase_ymd    = params[:purchase_date]
    purchase_amount      = params[:amount].to_f
    amount_without_tax   = params[:amount_without_tax]
    second_dealer_code   = params[:second_dealer_code]
    second_dealer_amount = params[:second_dealer_amount].to_f
    region               = params[:region]
    auth_token           = params[:auth_token]

    contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
    contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
		subtraction_amount = 0
		# ContractorUserチェック
		contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
		contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
		raise(ValidationError, 'unverified') if auth_token.blank? || contractor_user.blank?

		# Dealerチェック
		dealer = Dealer.find_by(dealer_code: dealer_code)
		raise(ValidationError, 'unmatch_dealer_type') if dealer.site_dealer?

		 # orders.payable_orders.where(dealer: dealer).sum(&:remaining_principal).to_f

		 total_site_credit_limit = contractor.sites.where(dealer: dealer).not_close.sum(:site_credit_limit).round(2)

		 # 支払い可能なCPAC以外のオーダー
		 not_site_orders = contractor.orders.payable_orders.includes(:dealer).where(site_id: nil, dealer: dealer)
 
		 # 支払い可能なCloseしたCPACのオーダー
		 closed_site_orders = contractor.orders.payable_orders.includes(:site, :dealer)
			 .where(sites: { closed: true }, dealer: dealer)
 
		 # Used Amountを取得
		 target_remaining_principal =
			 (not_site_orders + closed_site_orders).sum(&:remaining_principal).round(2)
 
		 # 残りの元本返済額
		 dealer_remaining_principal = (target_remaining_principal + total_site_credit_limit).round(2).to_f

		 render json: {
			total_site_credit_limit: total_site_credit_limit,
			not_site_orders: not_site_orders.map {|order| { id: order.id, remaining_principal: order.remaining_principal}},
			closed_site_orders: closed_site_orders.map {|order| { id: order.id, remaining_principal: order.remaining_principal}},
			target_remaining_principal: target_remaining_principal,
			dealer_remaining_principal: dealer_remaining_principal
		}
	end

	def check_over_dealer_type_limit
		tax_id               = params[:tax_id]
    order_number         = params[:order_number]
    product_key          = params[:product_id]
    dealer_code          = params[:dealer_code]
    rudy_purchase_ymd    = params[:purchase_date]
    purchase_amount      = params[:amount].to_f
    amount_without_tax   = params[:amount_without_tax]
    second_dealer_code   = params[:second_dealer_code]
    second_dealer_amount = params[:second_dealer_amount].to_f
    region               = params[:region]
    auth_token           = params[:auth_token]

    contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
    contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
		subtraction_amount = 0
		# ContractorUserチェック
		contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
		contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
		raise(ValidationError, 'unverified') if auth_token.blank? || contractor_user.blank?

		# Dealerチェック
		dealer = Dealer.find_by(dealer_code: dealer_code)
		raise(ValidationError, 'unmatch_dealer_type') if dealer.site_dealer?

		dealer_type = dealer.dealer_type

    dealer_type_limit_amount = contractor.dealer_type_limit_amount(dealer_type)
    dealer_type_remaining_principal = contractor.dealer_type_remaining_principal(dealer_type)

    expanded_credit_limit_amount =
      BigDecimal(dealer_type_limit_amount.to_s) * SystemSetting.credit_limit_additional_rate

    # recreateの場合は現在購入金額を引く
    remaining_principal = dealer_type_remaining_principal - subtraction_amount

    # 利用可能限度枠から残りの返済額を引く(マイナスは0にする)
    dealer_type_available_balance =
      [(expanded_credit_limit_amount - remaining_principal).round(2), 0].max

		render json: {
			purchase_amount: purchase_amount,
			dealer_type_limit_amount: dealer_type_limit_amount,
			dealer_type_remaining_principal: dealer_type_remaining_principal,
			credit_limit_additional_rate: SystemSetting.credit_limit_additional_rate,
			expanded_credit_limit_amount: expanded_credit_limit_amount,
			remaining_principal: remaining_principal,
			dealer_type_available_balance: dealer_type_available_balance,
			validate_failed: dealer_type_available_balance < purchase_amount
		}
	end

	def check_dealer_type_remaining_principal
		tax_id               = params[:tax_id]
    order_number         = params[:order_number]
    product_key          = params[:product_id]
    dealer_code          = params[:dealer_code]
    rudy_purchase_ymd    = params[:purchase_date]
    purchase_amount      = params[:amount].to_f
    amount_without_tax   = params[:amount_without_tax]
    second_dealer_code   = params[:second_dealer_code]
    second_dealer_amount = params[:second_dealer_amount].to_f
    region               = params[:region]
    auth_token           = params[:auth_token]

    contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
    contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
		subtraction_amount = 0
		# ContractorUserチェック
		contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
		contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
		raise(ValidationError, 'unverified') if auth_token.blank? || contractor_user.blank?

		# Dealerチェック
		dealer = Dealer.find_by(dealer_code: dealer_code)
		raise(ValidationError, 'unmatch_dealer_type') if dealer.site_dealer?

		dealer_type = dealer.dealer_type

		total_site_credit_limit = contractor.sites.includes(:dealer).where(dealers: {dealer_type: dealer_type})
			.not_close.sum(:site_credit_limit).round(2)

		# 支払い可能なCPAC以外のオーダー
		not_site_orders =
		contractor.orders.payable_orders.includes(:dealer).where(site_id: nil, dealers: {dealer_type: dealer_type})

		# 支払い可能なCloseしたCPACのオーダー
		closed_site_orders = contractor.orders.payable_orders.includes(:site, :dealer)
			.where(sites: { closed: true }, dealers: {dealer_type: dealer_type})

		# Used Amountを取得
		target_remaining_principal =
			(not_site_orders + closed_site_orders).sum(&:remaining_principal).round(2)

		# 残りの元本返済額
		dealer_type_remaining_principal = 
			(target_remaining_principal + total_site_credit_limit).round(2).to_f

		render json: {
			total_site_credit_limit: total_site_credit_limit,
			not_site_orders: not_site_orders,
			closed_site_orders: closed_site_orders,
			target_remaining_principal: target_remaining_principal,
			dealer_type_remaining_principal: dealer_type_remaining_principal
		}
	end

	def check_over_credit_limit
		tax_id               = params[:tax_id]
    order_number         = params[:order_number]
    product_key          = params[:product_id]
    dealer_code          = params[:dealer_code]
    rudy_purchase_ymd    = params[:purchase_date]
    purchase_amount      = params[:amount].to_f
    amount_without_tax   = params[:amount_without_tax]
    second_dealer_code   = params[:second_dealer_code]
    second_dealer_amount = params[:second_dealer_amount].to_f
    region               = params[:region]
    auth_token           = params[:auth_token]

    contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
    contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
		subtraction_amount = 0
		# ContractorUserチェック
		contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
		contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
		raise(ValidationError, 'unverified') if auth_token.blank? || contractor_user.blank?

		# Dealerチェック
		dealer = Dealer.find_by(dealer_code: dealer_code)
		raise(ValidationError, 'unmatch_dealer_type') if dealer.site_dealer?

		expanded_credit_limit_amount =
			BigDecimal(contractor.credit_limit_amount.to_s) * SystemSetting.credit_limit_additional_rate

		# 利用可能限度枠から残りの返済額を引く(マイナスは0にする)
		available_balance = [(expanded_credit_limit_amount - contractor.remaining_principal).round(2), 0].max

		available_balance < purchase_amount

		render json: {
			purchase_amount: purchase_amount,
			credit_limit_amount: contractor.credit_limit_amount,
			remaining_principal: contractor.remaining_principal,
			credit_limit_additional_rate: SystemSetting.credit_limit_additional_rate,
			expanded_credit_limit_amount: expanded_credit_limit_amount,
			remaining_principal: contractor.remaining_principal,
			available_balance: available_balance,
			validate_failed: available_balance < purchase_amount
		}
	end

	def check_remaining_principal
		tax_id               = params[:tax_id]
    order_number         = params[:order_number]
    product_key          = params[:product_id]
    dealer_code          = params[:dealer_code]
    rudy_purchase_ymd    = params[:purchase_date]
    purchase_amount      = params[:amount].to_f
    amount_without_tax   = params[:amount_without_tax]
    second_dealer_code   = params[:second_dealer_code]
    second_dealer_amount = params[:second_dealer_amount].to_f
    region               = params[:region]
    auth_token           = params[:auth_token]

    contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
    contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
		subtraction_amount = 0
		# ContractorUserチェック
		contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
		contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
		raise(ValidationError, 'unverified') if auth_token.blank? || contractor_user.blank?

		# Dealerチェック
		dealer = Dealer.find_by(dealer_code: dealer_code)
		raise(ValidationError, 'unmatch_dealer_type') if dealer.site_dealer?

		# アクティブなSiteのリミットの合計を取得
    total_site_credit_limit = contractor.sites.not_close.sum(:site_credit_limit).round(2).to_f

    # 支払い可能なSite以外のオーダー
    not_site_orders = contractor.orders.payable_orders.where(site_id: nil)

    # 支払い可能なCloseしたSiteのオーダー
    closed_site_orders = contractor.orders.payable_orders.includes(:site).where(sites: { closed: true })

    # Used Amountを取得
    target_remaining_principal =
      (not_site_orders + closed_site_orders).sum(&:remaining_principal).round(2)

    # 残りの元本返済額
    remaining_principal = (target_remaining_principal + total_site_credit_limit).round(2).to_f
		render json: {
			total_site_credit_limit: total_site_credit_limit,
			not_site_orders: not_site_orders,
			closed_site_orders: closed_site_orders,
			target_remaining_principal: target_remaining_principal,
			remaining_principal: remaining_principal
		}
	end

  def checks_due_ymds
    order = Order.find_by(id: params[:order_id])

    product = order.rescheduled_new_order? ? order.reschedule_product : order.product

    target_ymd = BusinessDay.today_ymd
    ymd_format = '%Y%m%d'

    # due_ymds = product.calc_due_ymds(BusinessDay.today_ymd)

    # 返却用の変数
    due_ymds = {}

    target_date = Date.parse(target_ymd, ymd_format)

    term_days =
      case product.product_key
      when 8
        15
      when 1, 2, 3, 11
        30
      when 4, 5, 6, 9
        60
      when 7, 10, 12, 13
        90
      else # 再約定した場合など
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
    product.number_of_installments.times.each do |i|
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


    render json: {
      target_ymd: target_ymd,
      target_date: target_date,
      product_key: product.product_key,
      term_days: term_days,
      advance_day: advance_day,
      advance_month: advance_month,
      advanced_date: advanced_date,
      closing_day: SystemSetting.closing_day,
      first_due_date: first_due_date,
      number_of_installments: product.number_of_installments,
      due_ymds: due_ymds
		}
  end

  def checks_interest
    order = Order.find_by(id: params[:order_id])

    product = order.rescheduled_new_order? ? order.reschedule_product : order.product

    target_ymd = BusinessDay.today_ymd
    ymd_format = '%Y%m%d'

    interest_rate = order.dealer&.interest_rate
    interest_rate ||= product.annual_interest_rate.to_f
    amount = order.purchase_amount

    # (BigDecimal(amount.to_s) * interest_rate * 0.01).round(2).to_f
    render json: {
      interest_rate: interest_rate,
      amount: amount,
      # total_interest: BigDecimal(amount) * interest_rate * 0.01
      total_interest: (BigDecimal(amount) * interest_rate * 0.01).round(2).to_f,
		}
    # total_interest = interest(amount, interest_rate)
  end

  def check_amari

    order = Order.find_by(id: params[:order_id])

    product = order.rescheduled_new_order? ? order.reschedule_product : order.product

    amount = params[:amount]
    result = 0
     # これ以上分割が出来ない値は、余りを出せないので0で返す
     if amount < 0.03
      result = 0
    else
      # 分割金額をタイバーツの小数点金額にするために、余りを1/100の金額にする
      result = ((amount * 100.0).round(2) % product.number_of_installments / 100.0).round(2)
    end

    render json: {
      amari: result,
      number_of_installments: product.number_of_installments
		}
  end

  def check_one_installment_amount_for_installment_principal
    order = Order.find_by(id: params[:order_id])

    product = order.rescheduled_new_order? ? order.reschedule_product : order.product

    amount = params[:amount]
    result = 0

    # これ以上分割が出来ない値は、分割金額を出せないのでamountをそのまま返す
    if (amount - amari(amount, product)) < 0.03
      result = amount
    else
      # 分割回数で割り切れる値にしてから分割回数で割る
      # number_of_installmentsを100で悪と、0.03 / 0.03 で 1になってしまう
      result = 
        ((amount - amari(amount, product)).round(2) / product.number_of_installments).round(2).to_f
    end
    render json: {
      amari: amari(amount, product),
      installment_principal: result,
      number_of_installments: product.number_of_installments
		}
  end

  def check_one_installment_amount_for_installment_interest
    order = Order.find_by(id: params[:order_id])

    product = order.rescheduled_new_order? ? order.reschedule_product : order.product

    amount = params[:amount]
    result = 0

    interest_rate = order.dealer&.interest_rate
    interest_rate ||= product.annual_interest_rate.to_f
    total_interest = interest(amount, interest_rate)

    # これ以上分割が出来ない値は、分割金額を出せないのでamountをそのまま返す
    if (total_interest - amari(total_interest, product)) < 0.03
      result = amount
    else
      # 分割回数で割り切れる値にしてから分割回数で割る
      # number_of_installmentsを100で悪と、0.03 / 0.03 で 1になってしまう
      result = 
        ((total_interest - amari(total_interest, product)).round(2) / product.number_of_installments).round(2).to_f
    end
    render json: {
      interest_rate: interest_rate,
      total_interest: total_interest,
      amari: amari(total_interest, product),
      installment_interest: result,
      number_of_installments: product.number_of_installments
		}
  end

  def check_installment_amounts
    order = Order.find_by(id: params[:order_id])

    product = order.rescheduled_new_order? ? order.reschedule_product : order.product

    amount = params[:amount]

    interest_rate = order.dealer&.interest_rate
    interest_rate ||= product.annual_interest_rate.to_f
    total_interest = interest(amount, interest_rate)
    installments = {}

    product.number_of_installments.times.each.with_index(1) {|hoge, installment_number|
      installment_principal = one_installment_amount(amount, product)
      installment_interest = one_installment_amount(total_interest, product)

      if installment_number == 1
        installment_principal += amari(amount, product)
        installment_interest += amari(total_interest, product)
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

    render json: { installments: installments, total_installment: total_installment }
  end

  def check_calc_payment_subtractions
    contractor_id  = params[:contractor_id]
    is_exemption_late_charge = params[:no_delay_penalty].to_s == 'true' # 遅損金の免除

    contractor = Contractor.find(contractor_id)

    payments = contractor.payments

    target_ymd = BusinessDay.today_ymd

    # 返却用変数
    calced_subtractions = {}

    # cashbackとexceeded算出用
    can_use_total_exceeded = contractor.exceeded_amount
    can_use_total_cashback = contractor.cashback_amount

    payments.each do |payment|
      # 支払い済みのpaymentは
      if payment.paid?
        calced_subtractions[payment.id] = {
          exceeded: 0.0,
          cashback: 0.0,
          total: 0.0,
          paid_exceeded: payment.paid_exceeded.to_f,
          paid_cashback: payment.paid_cashback.to_f,
          paid_total: (payment.paid_exceeded + payment.paid_cashback).round(2).to_f
        }

        next
      end

      # 支払い中のpaymentで獲得したキャッシュバックは、同じpaymentでは使用できないので、除外する
      exclusion_cashback_amount = payment.cashback_histories.gain_total
      can_use_total_cashback = (can_use_total_cashback - exclusion_cashback_amount).round(2)

      can_use_exceeded = 0.0
      can_use_cashback = 0.0

      # 残りの支払額(exceeded, cashbackの算出用)
      remaining_balance = is_exemption_late_charge ? payment.remaining_balance_exclude_late_charge
                                                   : payment.remaining_balance(target_ymd)
      # 使用できるexceededを算出する
      if can_use_total_exceeded > 0
        can_use_exceeded = [can_use_total_exceeded, remaining_balance].min
        # 全体から減算
        can_use_total_exceeded = (can_use_total_exceeded - can_use_exceeded).round(2)
        remaining_balance = (remaining_balance - can_use_exceeded).round(2)
      end

      # exceededがなくなったらcashbackを使用する
      if can_use_total_exceeded == 0 && can_use_total_cashback > 0
        # 使用できるcashback
        can_use_cashback = [can_use_total_cashback, remaining_balance].min
        # 全体から減算
        can_use_total_cashback = (can_use_total_cashback - can_use_cashback).round(2)
      end

      calced_subtractions[payment.id] = {
        exceeded: can_use_exceeded,
        cashback: can_use_cashback,
        total: (can_use_exceeded + can_use_cashback).round(2),
        paid_exceeded: payment.paid_exceeded.to_f,
        paid_cashback: payment.paid_cashback.to_f,
        paid_total: (payment.paid_exceeded + payment.paid_cashback).round(2).to_f
      }

      # 除外したキャッシュバックをトータルへ戻す（次のpaymentでは使用できるようにする）
      can_use_total_cashback = (can_use_total_cashback + exclusion_cashback_amount).round(2)
    end

    render json: { 
      payments: payments,
      payment_subtractions: calced_subtractions ,
      can_use_total_exceeded: can_use_total_exceeded,
      can_use_total_cashback: can_use_total_cashback
    }
  end

  def check_calc_paid_late_charge
    # contractor_id  = params[:contractor_id]
    payment_id = params[:payment_id]
    installment_id = params[:installment_id]

    # contractor = Contractor.find(contractor_id)

    payment = Payment.find(payment_id)

    installment = Installment.find(installment_id)

    target_ymd = params[:target_ymd] || BusinessDay.today_ymd

    # 約定日以前は遅損金の支払い(発生)は無し
    return  render json: { 
      target_ymd: target_ymd,
      due_ymd: installment.due_ymd ,
      paid_late_charge: 0.0 
    } if Date.parse(target_ymd) <= Date.parse(installment.due_ymd)
    # 分割の支払いが完了したものは、完了時の遅損金を返す
    return render json: { 
      paid: installment.paid?,
      paid_late_charge: installment.paid_late_charge.to_f 
    } if installment.paid?

    installment_history = installment.target_installment_history(target_ymd)

    render json: { installment_history: installment_history, paid_late_charge:  installment_history.paid_late_charge.to_f }
  end

  def check_calc_remaining_amount_without_late_charge
    # contractor_id  = params[:contractor_id]
    payment_id = params[:payment_id]
    installment_id = params[:installment_id]
    is_exemption = params[:no_delay_penalty].to_s == 'true' # 遅損金の免除

    # contractor = Contractor.find(contractor_id)

    payment = Payment.find(payment_id)

    installment = Installment.find(installment_id)

    target_ymd = params[:target_ymd] || BusinessDay.today_ymd

    installment_history = installment.target_installment_history(target_ymd)

    remaining_principal = installment.principal - installment_history.paid_principal
    remaining_interest = installment.interest - installment_history.paid_interest

    render json: {
      installment_history: installment_history,
      remaining_principal: remaining_principal,
      remaining_interest: remaining_interest,
      remaining_amount_without_late_charge: (remaining_principal + remaining_interest).round(2).to_f
    }
  end

  def check_calc_start_ymd
    # contractor_id  = params[:contractor_id]
    payment_id = params[:payment_id]
    installment_id = params[:installment_id]
    is_exemption = params[:no_delay_penalty].to_s == 'true' # 遅損金の免除

    # contractor = Contractor.find(contractor_id)

    payment = Payment.find(payment_id)

    installment = Installment.find(installment_id)

    target_ymd = params[:target_ymd] || BusinessDay.today_ymd

    result = nil
     # 移動した起算日があれば
     if installment.calc_late_charge_start_ymd(target_ymd).present?
      # リセットされた起算日を取得
      result = installment.calc_late_charge_start_ymd(target_ymd)
    elsif installment.installment_number == 1
      # 1回目は入力日
      result = installment.order.input_ymd
    else
      # 2回目以降は1つ前の約定日
      if installment.order.canceled?
        # Order Basis(Reporting CSV)用にキャンセル(installment.deleted)も含める

        # キャンセル前の有効なinstallmentsを取得
        canceled_installments =
        installment.order.installments.unscope(where: :deleted)[-order.installment_count..-1]

        # キャンセル前の有効なinstallmentかの判定
        is_canceled_installment = canceled_installments.map(&:id).include?(id)

        if is_canceled_installment
          result = canceled_installments
            .find{|installment| installment.installment_number == installment_number - 1}.due_ymd
        else
          installment.order.installments.unscope(where: :deleted)
            .find_by(installment_number: installment_number - 1).due_ymd
        end
      else
        result = installment.order.installments.find_by(installment_number: installment_number - 1).due_ymd
      end
    end

    render json: {
      calc_start_ymd: result
    }
  end

  def check_calc_late_charge_days
    # contractor_id  = params[:contractor_id]
    payment_id = params[:payment_id]
    installment_id = params[:installment_id]
    is_exemption = params[:no_delay_penalty].to_s == 'true' # 遅損金の免除

    # contractor = Contractor.find(contractor_id)

    payment = Payment.find(payment_id)

    installment = Installment.find(installment_id)

    target_ymd = params[:target_ymd] || BusinessDay.today_ymd
    ymd_format = '%Y%m%d'

    # 約定日
    due_date = Date.parse(installment.due_ymd, ymd_format)
    # 指定日
    target_date = Date.parse(target_ymd, ymd_format)

    # 指定日が約定日以前は遅延はない
    return render json: {
      late_charge_days: 0
    } if (target_date - due_date).to_i <= 0

    # 起算日
    start_ymd = installment.calc_start_ymd(target_ymd)

    # 起算日をDateへ
    start_date = Date.parse(start_ymd, ymd_format)

    # 日数が有理数で返るので、整数へ変換。両端方式なので、起算日の分の1日を足す
    late_charge_days = (target_date - start_date).to_i + 1

    # マイナスは0にする
    # late_charge_days
    render json: {
      late_charge_days: [late_charge_days, 0].max
    }
  end

  def check_calc_late_charge
    # contractor_id  = params[:contractor_id]
    payment_id = params[:payment_id]
    installment_id = params[:installment_id]
    is_exemption = params[:no_delay_penalty].to_s == 'true' # 遅損金の免除

    # contractor = Contractor.find(contractor_id)

    payment = Payment.find(payment_id)

    installment = Installment.find(installment_id)

    target_ymd = params[:target_ymd] || BusinessDay.today_ymd

    # 完済後
    if installment.paid?
      # 免除した場合は 0.0、免除がない場合は 支払った金額
      return render json: {
        exist_exemption_late_charge: installment.exist_exemption_late_charge,
        paid_late_charge: installment.paid_late_charge.to_f,
        late_charge: installment.exist_exemption_late_charge ? 0.0 : installment.paid_late_charge.to_f
      }
    end

    # 免除フラグが真なら払った分だけを返す(remainingは0.0になる)
    return render json: {
      exempt_late_charge: installment.exempt_late_charge,
      late_charge: installment.paid_late_charge.to_f
    } if installment.exempt_late_charge

    # 遅損金免除の判定
    return render json: {
      is_exemption: is_exemption,
      late_charge: installment.paid_late_charge.to_f
    } if is_exemption

    # 約定日以前は遅損金なし
    return render json: {
      target_ymd: target_ymd,
      due_ymd: installment.due_ymd,
      over_due: installment.over_due?(target_ymd),
      late_charge: 0.0
    } unless installment.over_due?(target_ymd)

    # 遅損金を除いた元本と利息の、残りの支払額
    remaining_amount_without_late_charge = installment.calc_remaining_amount_without_late_charge(target_ymd)

    # 遅延日数(支払いが完了していれば、完了日で算出)
    late_charge_days = installment.calc_late_charge_days(target_ymd)

    # 遅損金
    delay_penalty_rate = installment.order.belongs_to_project_finance? ?
      installment.order.project.delay_penalty_rate : installment.contractor.delay_penalty_rate

    calced_delay_penalty_rate = delay_penalty_rate / 100.0
    calced_amount = BigDecimal(remaining_amount_without_late_charge.to_s) * calced_delay_penalty_rate
    calced_days = BigDecimal(late_charge_days.to_s) / 365

    original_late_charge_amount = (calced_amount * calced_days).floor(2).to_f


    late_charge_amount =
      if installment.calc_late_charge_start_ymd(target_ymd).present?
        # 起算日の前日を取得
        yesterday_start_ymd =
          Date.parse(installment.calc_late_charge_start_ymd(target_ymd)).yesterday.strftime('%Y%m%d')

        # 起算日以前の支払った遅損金を算出
        paid_late_charge_before_late_charge_start_ymd = installment.calc_paid_late_charge(yesterday_start_ymd)

        # 起算日より前の遅損金 + 起算日以降の遅損金
        paid_late_charge_before_late_charge_start_ymd + original_late_charge_amount
      else
        # 支払った金額を下回らない様に調整
        [installment.calc_paid_late_charge(target_ymd), original_late_charge_amount].max
      end

    # 計算誤差は四捨五入
    calc_late_charge = late_charge_amount.round(2).to_f
    return render json: {
      target_ymd: target_ymd,
      remaining_amount_without_late_charge: remaining_amount_without_late_charge,
      late_charge_days: late_charge_days,
      delay_penalty_rate: delay_penalty_rate,
      calced_delay_penalty_rate: calced_delay_penalty_rate,
      calced_amount: calced_amount,
      calced_days: calced_days,
      original_late_charge_amount: original_late_charge_amount,
      calc_late_charge_start_ymd: installment.calc_late_charge_start_ymd(target_ymd),
      yesterday_start_ymd: yesterday_start_ymd,
      paid_late_charge_before_late_charge_start_ymd: paid_late_charge_before_late_charge_start_ymd,
      calc_late_charge: calc_late_charge,
    }
  end

  def check_calc_remaining_late_charge
     # contractor_id  = params[:contractor_id]
     payment_id = params[:payment_id]
     installment_id = params[:installment_id]
     is_exemption = params[:no_delay_penalty].to_s == 'true' # 遅損金の免除
 
     # contractor = Contractor.find(contractor_id)
 
     payment = Payment.find(payment_id)
 
     installment = Installment.find(installment_id)
 
     target_ymd = params[:target_ymd] || BusinessDay.today_ymd
     ymd_format = '%Y%m%d'

    render json: {
      remaining_late_charge: [(installment.calc_late_charge(target_ymd) - installment.calc_paid_late_charge(target_ymd)), 0].max.round(2).to_f
    }
  end

  def check_calc_subtract
    contractor_id  = params[:contractor_id]
    payment_ymd    = params[:payment_ymd]
    payment_amount = params[:payment_amount].to_f
    comment        = params[:comment]
    is_exemption_late_charge = params[:no_delay_penalty].to_s == 'true' # 遅損金の免除

    payment_id = params[:payment_id]
    installment_id = params[:installment_id]

    payment = Payment.find(payment_id)
    installment = Installment.find(installment_id)
    contractor = Contractor.find(contractor_id)

    payments = contractor.payments

    target_ymd = BusinessDay.today_ymd
    ymd_format = '%Y%m%d'

    payment_subtractions =
        CalcPaymentSubtractions.new(contractor, payment_ymd, is_exemption_late_charge).call

    payment_subtraction = payment_subtractions[payment.id]
    exceeded = payment_subtraction[:exceeded]
    cashback = payment_subtraction[:cashback]
    remaining_late_charge = installment.calc_remaining_late_charge(payment_ymd)

    # exceededの減算
    if exceeded > 0
      # 差引額
      subtract_amount = [remaining_late_charge, exceeded].min

      # 元の額へ適用する
      remaining_late_charge = (remaining_late_charge - subtract_amount).round(2).to_f
      exceeded = (exceeded - subtract_amount).round(2).to_f
    end

    # cashbackの減算
    if remaining_late_charge > 0 && cashback > 0
      # 差引額
      subtract_amount = [remaining_late_charge, cashback].min

      # 元の額へ適用する
      remaining_late_charge = (remaining_late_charge - subtract_amount).round(2).to_f
      cashback = (cashback - subtract_amount).round(2).to_f
    end

    # 入金額の減算
    if remaining_late_charge > 0 && payment_amount > 0
      # 差引額
      subtract_amount = [remaining_late_charge, payment_amount].min

      # 元の額へ適用する
      remaining_late_charge = (remaining_late_charge - subtract_amount).round(2).to_f
      payment_amount = (payment_amount - subtract_amount).round(2).to_f
    end

    render json: {
      remaining_late_charge: remaining_late_charge,
      exceeded: exceeded,
      cashback: cashback,
      payment_amount: payment_amount
    }
  end

  def check_find_receive_amount_detail_data
    receive_amount_detail_data_arr = []

    payment_id = params[:payment_id]
    installment_id = params[:installment_id]

    payment = Payment.find(payment_id)

    # 対象のinstallmentsをソートして取得
    installments = payment.installments.payable_installments.appropriation_sort

    # 履歴データの初期化
    installments.each do |installment|
      receive_amount_detail_data_arr.push({
        installment_id: installment.id,
        exceeded_paid_amount: 0,
        cashback_paid_amount: 0,
      })
    end

    result = receive_amount_detail_data_arr.find do |item|
      item[:installment_id] == installment_id
    end
    
    render json: {
      receive_amount_detail_data_arr: receive_amount_detail_data_arr,
      receive_amount_detail_data: result,
    }
  end

  private
  # 余りの算出
  def amari(amount, product)
    # これ以上分割が出来ない値は、余りを出せないので0で返す
    if amount < 0.03
      0
    else
      # 分割金額をタイバーツの小数点金額にするために、余りを1/100の金額にする
      ((amount * 100.0).round(2) % product.number_of_installments / 100.0).round(2)
    end
  end

  def interest(amount, interest_rate = nil)
    (BigDecimal(amount.to_s) * interest_rate * 0.01).round(2).to_f
  end

  # 1回分の分割金額(元本、利子の計算用)
  def one_installment_amount(amount, product)
    # これ以上分割が出来ない値は、分割金額を出せないのでamountをそのまま返す
    if (amount - amari(amount, product)) < 0.03
      amount
    else
      # 分割回数で割り切れる値にしてから分割回数で割る
      # number_of_installmentsを100で悪と、0.03 / 0.03 で 1になってしまう
      ((amount - amari(amount, product)).round(2) / product.number_of_installments).round(2).to_f
    end
  end

  def calc_subtract(target_amount, exceeded, cashback, input_amount)
    # exceededの減算
    if exceeded > 0
      # 差引額
      subtract_amount = [target_amount, exceeded].min

      # 元の額へ適用する
      target_amount = (target_amount - subtract_amount).round(2).to_f
      exceeded = (exceeded - subtract_amount).round(2).to_f
    end

    # cashbackの減算
    if target_amount > 0 && cashback > 0
      # 差引額
      subtract_amount = [target_amount, cashback].min

      # 元の額へ適用する
      target_amount = (target_amount - subtract_amount).round(2).to_f
      cashback = (cashback - subtract_amount).round(2).to_f
    end

    # 入金額の減算
    if target_amount > 0 && input_amount > 0
      # 差引額
      subtract_amount = [target_amount, input_amount].min

      # 元の額へ適用する
      target_amount = (target_amount - subtract_amount).round(2).to_f
      input_amount = (input_amount - subtract_amount).round(2).to_f
    end

    [target_amount, exceeded, cashback, input_amount]
  end
end
