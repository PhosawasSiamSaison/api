class ChangeProduct
  include FormatterModule

  def initialize(order, product)
    @order = order
    @product = product
  end

  def call
    ActiveRecord::Base.transaction do
      # 変更前のdue_ymdを保持
      order.change_product_before_due_ymd = order.first_due_ymd

      # 削除するinstallmentのidを取得(オブジェクトだと再参照されるのでidを保持する)
      delete_target_installment_ids = order.installments.ids

      # orderの変更
      order.update!(
        product: product,
        installment_count: product.number_of_installments,
      )

      # 約定日の算出
      due_ymds = product.calc_due_ymds(order.input_ymd)

      # 分割金額の取得
      installment_amounts =
        product.installment_amounts(order.purchase_amount, order.dealer.interest_rate)

      order.installment_count.times.each.with_index(1) do |_, i|
        # 約定日の取得
        due_ymd = due_ymds[i]

        # 支払い金額情報の取得
        installment_amount_data = installment_amounts[:installments][i]

        # Paymentの作成、または更新
        payment = Payment.find_or_initialize_by(
          contractor: order.contractor,
          due_ymd: due_ymd,
        )

        # ステータスを更新する
        update_payment_status(payment) if payment.new_record?

        # 支払い金額を追加
        payment.total_amount += installment_amount_data[:total]

        payment.save!

        # Installmentの作成
        create_installment(order, payment, i, due_ymd, installment_amount_data)
      end

      # 既存のpaymentの変更とinstallmentの削除
      Installment.find(delete_target_installment_ids).each do |installment|
        installment.update!(deleted: true)
        installment.remove_from_payment
      end
    end

    { success: true }
  end

  private
  attr_reader :order, :product, :memo

  def update_payment_status(payment)
    due_date = Date.parse(payment.due_ymd, '%Y%m%d')

    # DueDateを過ぎている
    if due_date < BusinessDay.today
      payment.status = :over_due

    # DueDateが15日
    elsif due_date.day == SystemSetting.closing_day
      # 先月の15日 < 業務日
      if due_date.months_ago(1) < BusinessDay.today
        payment.status = :next_due

      # 業務日が先月の15日より前
      else
        payment.status = :not_due_yet
      end

    # DueDateが月末
    else
      # DueDateが今月
      if due_date.strftime(ym_format) == BusinessDay.today.strftime(ym_format)
        payment.status = :next_due

      # DueDateが先月以前
      else
        payment.status = :not_due_yet
      end
    end
  end

  def create_installment(order, payment, installment_number, due_ymd, installment_amount_data)
    installment = Installment.new
    installment.contractor = order.contractor
    installment.order      = order
    installment.payment    = payment
    installment.installment_number = installment_number
    installment.due_ymd    = due_ymd
    installment.principal  = installment_amount_data[:principal]
    installment.interest   = installment_amount_data[:interest]

    # Installment
    installment.save!
  end
end
