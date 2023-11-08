# frozen_string_literal: true
# == Schema Information
#
# Table name: installments
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)
#  order_id             :integer          not null
#  payment_id           :integer
#  installment_number   :integer          not null
#  rescheduled          :boolean          default(FALSE), not null
#  exempt_late_charge   :boolean          default(FALSE), not null
#  due_ymd              :string(8)        not null
#  paid_up_ymd          :string(8)
#  principal            :decimal(10, 2)   default(0.0), not null
#  interest             :decimal(10, 2)   default(0.0), not null
#  paid_principal       :decimal(10, 2)   default(0.0), not null
#  paid_interest        :decimal(10, 2)   default(0.0), not null
#  paid_late_charge     :decimal(10, 2)   default(0.0), not null
#  used_exceeded        :decimal(10, 2)   default(0.0)
#  used_cashback        :decimal(10, 2)   default(0.0)
#  reduced_site_limit   :decimal(10, 2)   default(0.0)
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class Installment < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :contractor, optional: true # optionalをtrueにするための定義。実際contractorはdelegateから取得される
  belongs_to :order
  delegate :contractor, to: :order # order経由でcontractorを取得
  belongs_to :payment, optional: true
  has_many :installment_histories
  has_many :exemption_late_charges
  has_many :adjust_repayment_histories

  validates :payment_id, absence: true, if: -> { order.project_phase_site_id.present? }

  # 支払い可能分
  scope :payable_installments, -> { where(paid_up_ymd: nil, rescheduled: false) }

  # 古いリスケを除外
  scope :exclude_rescheduled_installments, -> { where(rescheduled: false) }

  # 充当をしていく順番
  scope :appropriation_sort, -> {
    eager_load(:order).order(
      'orders.input_ymd ASC, orders.purchase_ymd ASC, orders.created_at ASC, orders.id ASC'
    )
  }

  # Orderにinput_ymdがあるもののみ
  scope :inputed_date_installments, -> {
    eager_load(:order).where.not(orders: { input_ymd: nil })
  }

  after_create do
    # レコード作成後に履歴を作成する
    installment_history = InstallmentHistory.new(
      contractor: contractor,
      order: order,
      installment: self,
      payment: payment,
      from_ymd: order.purchase_ymd
    )
    installment_history.set_installment_paid_amount
    installment_history.save!
  end

  class << self
    def remaining_principal
      principal = payable_installments.sum(:principal)
      paid_principal = payable_installments.sum(:paid_principal)

      # 残りの元本返済額
      (principal - paid_principal).round(2).to_f
    end

    def remaining_interest
      interest = payable_installments.sum(:interest)
      paid_interest = payable_installments.sum(:paid_interest)

      # 残りの利子返済額
      (interest - paid_interest).round(2).to_f
    end
  end

  # save & installment_history の作成・更新
  def save_with_history(from_ymd)
    # 同じ日付のhistoryがなければ新規で作成
    installment_history = installment_histories.find_or_initialize_by(from_ymd: from_ymd)

    # 既存(開始日が同日)のhistoryがなければ
    if installment_history.new_record?
      # 現在の最新を取得
      prev_history = installment_histories.order(:to_ymd).last
      # 1日前で
      yesterday_ymd = Date.parse(from_ymd).yesterday.strftime(ymd_format)
      # 過去のhistoryとして更新する
      prev_history.update!(to_ymd: yesterday_ymd)

      # 新しいhistoryへ値を引き継ぐ
      installment_history.late_charge_start_ymd = prev_history.late_charge_start_ymd
      installment_history.contractor            = prev_history.contractor
      installment_history.order                 = prev_history.order
      installment_history.payment               = prev_history.payment
    end

    # หากมีการจัดสรรเงินต้น (หากจำนวนเงินที่จ่ายเพิ่มขึ้น)
    if paid_principal > paid_principal_was
      # อัปเดตวันถัดจากวันที่ชำระเงินเป็นวันเริ่มต้น
      payment_tomorrow_ymd = Date.parse(from_ymd).tomorrow.strftime('%Y%m%d')
      installment_history.late_charge_start_ymd = payment_tomorrow_ymd
    end

    # installmentの値をセット
    installment_history.set_installment_paid_amount

    installment_history.save!
    save!
  end

  def target_installment_history(target_ymd)
    installment_histories.by_target_ymd(target_ymd)
  end

  # 指定日時点の元本と利息の残りの支払額
  def calc_remaining_amount_without_late_charge(target_ymd)
    installment_history = target_installment_history(target_ymd)

    remaining_principal = principal - installment_history.paid_principal
    remaining_interest = interest - installment_history.paid_interest

    (remaining_principal + remaining_interest).round(2).to_f
  end

  # 指定日時点の遅損金を算出
  def calc_paid_late_charge(target_ymd = BusinessDay.today_ymd)
    # 約定日以前は遅損金の支払い(発生)は無し
    return 0.0 if Date.parse(target_ymd) <= Date.parse(due_ymd)
    # 分割の支払いが完了したものは、完了時の遅損金を返す
    return paid_late_charge.to_f if paid?

    installment_history = target_installment_history(target_ymd)

    installment_history.paid_late_charge.to_f
  end

  def calc_late_charge_start_ymd(target_ymd)
    installment_histories.by_target_ymd(target_ymd).late_charge_start_ymd
  end

  # 起算日を算出する
  def calc_start_ymd(target_ymd)
    # หากมีการย้ายวันเริ่มต้น
    if calc_late_charge_start_ymd(target_ymd).present?
      # รับวันที่เริ่มต้นการรีเซ็ต
      calc_late_charge_start_ymd(target_ymd)
    elsif installment_number == 1
      # 1回目は入力日
      order.input_ymd
    else
      # 2回目以降は1つ前の約定日
      if order.canceled?
        # Order Basis(Reporting CSV)用にキャンセル(installment.deleted)も含める

        # キャンセル前の有効なinstallmentsを取得
        canceled_installments =
          order.installments.unscope(where: :deleted)[-order.installment_count..-1]

        # キャンセル前の有効なinstallmentかの判定
        is_canceled_installment = canceled_installments.map(&:id).include?(id)

        if is_canceled_installment
          canceled_installments
            .find{|installment| installment.installment_number == installment_number - 1}.due_ymd
        else
          order.installments.unscope(where: :deleted)
            .find_by(installment_number: installment_number - 1).due_ymd
        end
      else
        order.installments.find_by(installment_number: installment_number - 1).due_ymd
      end
    end
  end

  # 遅損の日数を算出
  def calc_late_charge_days(target_ymd)
    # 約定日
    due_date = Date.parse(due_ymd, ymd_format)
    # 指定日
    target_date = Date.parse(target_ymd, ymd_format)

    # 指定日が約定日以前は遅延はない
    return 0 if (target_date - due_date).to_i <= 0

    # 起算日
    start_ymd = calc_start_ymd(target_ymd)

    # 起算日をDateへ
    start_date = Date.parse(start_ymd, ymd_format)

    # 日数が有理数で返るので、整数へ変換。両端方式なので、起算日の分の1日を足す
    late_charge_days = (target_date - start_date).to_i + 1

    # マイナスは0にする
    [late_charge_days, 0].max
  end

  # 日付時点の遅損金を計算(支払い済みを含む)
  # TODO is_exemptionのパターンがよくわからないので外に出す
  # TODO 命名がわかりづらいので total の接頭辞をつける
  def calc_late_charge(target_ymd = BusinessDay.today_ymd, is_exemption = false)
    # 完済後
    if paid?
      # 免除した場合は 0.0、免除がない場合は 支払った金額
      return exist_exemption_late_charge ? 0.0 : paid_late_charge.to_f
    end

    # 免除フラグが真なら払った分だけを返す(remainingは0.0になる)
    return paid_late_charge.to_f if exempt_late_charge

    # 遅損金免除の判定
    return paid_late_charge.to_f if is_exemption

    # 約定日以前は遅損金なし
    return 0.0 unless over_due?(target_ymd)

    # 遅損金を除いた元本と利息の、残りの支払額
    remaining_amount_without_late_charge = calc_remaining_amount_without_late_charge(target_ymd)

    # 遅延日数(支払いが完了していれば、完了日で算出)
    late_charge_days = calc_late_charge_days(target_ymd)

    # 遅損金
    delay_penalty_rate = order.belongs_to_project_finance? ?
      order.project.delay_penalty_rate : contractor.delay_penalty_rate

    calced_delay_penalty_rate = delay_penalty_rate / 100.0
    calced_amount = BigDecimal(remaining_amount_without_late_charge.to_s) * calced_delay_penalty_rate
    calced_days = BigDecimal(late_charge_days.to_s) / 365

    original_late_charge_amount = (calced_amount * calced_days).floor(2).to_f

    late_charge_amount =
      if calc_late_charge_start_ymd(target_ymd).present?
        # รับวันก่อนวันที่เริ่มต้น
        yesterday_start_ymd =
          Date.parse(calc_late_charge_start_ymd(target_ymd)).yesterday.strftime('%Y%m%d')

        # คำนวณการสูญเสียล่าช้าที่จ่ายก่อนวันที่เริ่มต้น
        paid_late_charge_before_late_charge_start_ymd = calc_paid_late_charge(yesterday_start_ymd)

        # ขาดทุนล่าช้าก่อนวันที่คำนวณ + ขาดทุนล่าช้าหลังวันที่คำนวณ
        paid_late_charge_before_late_charge_start_ymd + original_late_charge_amount
      else
        # ปรับเพื่อไม่ให้ต่ำกว่าจำนวนเงินที่จ่ายไป
        [calc_paid_late_charge(target_ymd), original_late_charge_amount].max
      end

    # ข้อผิดพลาดในการคำนวณจะถูกปัดเศษ
    late_charge_amount.round(2).to_f
  end

  def paid?
    paid_up_ymd.present?
  end

  def over_due?(target_ymd = BusinessDay.today_ymd)
    Date.parse(due_ymd) < Date.parse(target_ymd)
  end

  # 遅損金なしの支払い予定金額
  # (値は変動しない)
  def total_amount
    (principal + interest).round(2).to_f
  end

  # 支払い予定金額の合計(遅損金の算出あり)
  # (支払いが完了しても、完済日以降では遅損金が加算されていくので指定日が必須)
  def calc_total_amount(target_ymd = BusinessDay.today_ymd)
    (principal + interest + calc_late_charge(target_ymd)).round(2).to_f
  end

  # 支払った金額の合計
  # (未払いなら 0になる。支払いが完了すれば、最終的に支払った金額になる)
  def paid_total_amount
    (paid_principal + paid_interest + paid_late_charge).round(2).to_f
  end

  # 元本の支払い残金
  def remaining_principal
    [(principal - paid_principal), 0].max.round(2).to_f
  end

  # 利息の支払い残金
  def remaining_interest
    [(interest - paid_interest), 0].max.round(2).to_f
  end

  # 遅損金の支払い残金
  def calc_remaining_late_charge(target_ymd = BusinessDay.today_ymd)
    [(calc_late_charge(target_ymd) - calc_paid_late_charge(target_ymd)), 0].max.round(2).to_f
  end

  # 残りの支払額(遅損金を含む)
  def remaining_balance(target_ymd = BusinessDay.today_ymd)
    (remaining_principal + remaining_interest + calc_remaining_late_charge(target_ymd)).round(2).to_f
  end

  # 残りの支払額(遅損金を含まない)
  def remaining_balance_exclude_late_charge
    (remaining_principal + remaining_interest).round(2).to_f
  end

  # 所属しているPaymentからinstallmentを取り除く
  def remove_from_payment
    # PFオーダーの場合はpaymentがないので除外
    return if order.project_phase_site.present?

    # Paymentからtotal_amountを引く
    prev_total_amount = (payment.total_amount - total_amount).round(2)

    if prev_total_amount == 0
      # 紐付くinstallmentがなくなった場合(total_amountが0になった)、そのPaymentを削除する
      payment.update!(deleted: true)
    elsif prev_total_amount > 0
      # Installmentの金額を引いて保存
      payment.total_amount = prev_total_amount

      # InputDateの入ったinstallmentが完済していればステータスを更新する
      # (InstallmentsにInputDateありがなければ更新しない)
      if payment.installments.presence&.all?(&:paid?) || false
        # 支払い済みのデータをセットする
        payment.status = 'paid'
        payment.paid_up_ymd = payment.installments.maximum(:paid_up_ymd)
        payment.paid_up_operated_ymd = BusinessDay.today_ymd
      end

      payment.save!
    else
      # マイナスにはならない想定
      raise '予期せぬ処理：prev_total_amountがマイナスになる'
    end
  end

  def exist_exemption_late_charge
    exemption_late_charges.present?
  end

  # 一部支払いずみを戻す処理の可能判定
  def can_adjust_repayment(login_user)
    login_user.md? && # 権限があること
    !paid? && # 完済していないこと
    paid_total_amount > 0 # 一部支払い済みであること
  end

  def deleted?
    deleted == 1
  end
end
