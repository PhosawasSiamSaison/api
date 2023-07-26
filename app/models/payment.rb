# == Schema Information
#
# Table name: payments
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :integer          not null
#  due_ymd              :string(8)        not null
#  paid_up_ymd          :string(8)
#  paid_up_operated_ymd :string(8)
#  total_amount         :decimal(10, 2)   default(0.0), not null
#  paid_total_amount    :decimal(10, 2)   default(0.0), not null
#  paid_exceeded        :decimal(10, 2)   default(0.0), not null
#  paid_cashback        :decimal(10, 2)   default(0.0), not null
#  status               :integer          default("not_due_yet"), not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class Payment < ApplicationRecord
  default_scope { where(deleted: 0).order(due_ymd: :asc) }

  belongs_to :contractor

  # 古いリスケ分が含まれる
  has_many :all_installments, class_name: :Installment

  # 古いリスケ分は除外
  has_many :installments, -> {
    eager_load(:order)
      .where(orders: { rescheduled_new_order_id: nil })
      .where('orders.input_ymd IS NOT NULL')
  }

  # InputDateなしを含む installments
  has_many :include_no_input_date_installments, -> {
    eager_load(:order)
      .where(orders: { rescheduled_new_order_id: nil })
  }, class_name: :Installment

  # 古いリスケ分は除外
  has_many :orders, -> { exclude_rescheduled }, through: :all_installments

  # InputDateありのみのOrders
  has_many :exclude_no_input_date_orders,
    -> { exclude_rescheduled }, through: :installments, source: "order"

  has_many :cashback_histories, through: :orders

  enum status: { not_due_yet: 1, next_due: 2, paid: 3, over_due: 4 }

  # 返済可能なPaymentのステータス
  scope :appropriate_payments, -> {
    where(status: [:not_due_yet, :next_due, :over_due])
  }

  # installmentsのorderのinput_ymdはないものは除外
  scope :exclude_not_input_ymd, -> {
    eager_load(:orders).where('input_ymd IS NOT NULL')
  }

  # Payment (From Contractor) List に表示するPayment
  scope :payment_from_contractor_payments, -> {
    # 当日に支払いが完了した分
    paid_today = paid.where(paid_up_operated_ymd: BusinessDay.today_ymd)

    # 以下の順番で表示する
    over_due + paid_today + next_due + not_due_yet
  }

  scope :paid_over_due_payments, -> {
    paid.where("payments.due_ymd < payments.paid_up_ymd")
  }

  class << self
    def search_contractor_payments(params)
      over_due +
      next_due +
      not_due_yet +
      (params[:include_paid].to_s == 'true' ? paid : [])
    end

    # Repayment History
    def search_repayment_history(params)
      relation = paid.eager_load(:contractor)
                  .order(paid_up_ymd: :DESC, due_ymd: :ASC, created_at: :ASC, id: :ASC)

      # TAX ID(tax_id)
      if params.dig(:search, :tax_id).present?
        tax_id   = params.dig(:search, :tax_id)
        relation = relation.where("contractors.tax_id LIKE ?", "#{tax_id}%")
      end

      # Company Name
      if params.dig(:search, :company_name).present?
        company_name = params.dig(:search, :company_name)
        relation     = relation.where("CONCAT(en_company_name, th_company_name) LIKE ?", "%#{company_name}%")
      end

      # Due Date(due_ymd)
      if params.dig(:search, :due_ymd).present?
        due_ymd = params.dig(:search, :due_ymd)

        relation = relation.where(due_ymd: due_ymd)
      end

      # Paid Up Date(paid_up_ymd)
      if params.dig(:search, :paid_up_ymd).present?
        paid_up_ymd = params.dig(:search, :paid_up_ymd)

        relation = relation.where(paid_up_ymd: paid_up_ymd)
      end

      # Over Due Only
      if params.dig(:search, :over_due_only).to_s == 'true'
        relation = relation.where("due_ymd < paid_up_ymd")
      end

      # Used Cashback Only
      if params.dig(:search, :used_cashback_only).to_s == 'true'
        relation = relation.where("0 < paid_cashback")
      end

      # Paging
      if params[:page].present? && params[:per_page].present?
        result = paginate(params[:page], relation, params[:per_page])
      else
        result = relation
      end

      [result, relation.count]
    end

    # Due Basis CSV の対象Payment
    def due_basis_data
      all
        .includes(
          :contractor,
          :installments,
          installments: [:exemption_late_charges, :installment_histories],
        )
        .unscope(:order).order(due_ymd: :DESC)
        .reject{|payment| payment.all_orders_input_ymd_blank?} # 1つもInputDate入力済みがなければ除外
    end
  end

  # ステータスを next_due へ更新する
  def update_to_next_due
    # 状態のチェック
    raise 'not_due_yet 以外は next_due へ更新できません' unless not_due_yet?

    update!(status: :next_due)
  end

  # ステータスを over_due へ更新する
  def update_to_over_due
    # 状態のチェック
    raise 'next_due 以外は over_due へ更新できません' unless next_due?
    raise '支払完了日が入力されているものは over_due へ更新できません' if paid_up_ymd.present?
    raise 'すでに支払いが完了しているものは over_due へ更新できません' if total_amount <= paid_total_amount

    update!(status: :over_due)
  end

  # 支払い合計金額(遅損金を含む)
  def due_amount
    if paid?
      paid_total_amount
    else
      today_ymd = BusinessDay.today_ymd
      installments.inject(0) {|sum, installment|
        sum + installment.calc_total_amount(today_ymd)
      }.round(2).to_f
    end
  end

  # 残りの支払額(遅損金を含む)
  def remaining_balance(target_ymd = BusinessDay.today_ymd)
    installments.inject(0) {|sum, installment|
      sum + installment.remaining_balance(target_ymd)
    }.round(2).to_f
  end

  # 残りの支払額(遅損金は含まない)
  def remaining_balance_exclude_late_charge
    installments.inject(0) {|sum, installment|
      sum + installment.remaining_balance_exclude_late_charge
    }.round(2).to_f
  end

  # 支払い予定の元本
  def total_principal
    installments.sum {|installment|
      installment.principal
    }.round(2).to_f
  end

  # 支払い予定の利息
  def total_interest
    installments.inject(0) {|sum, installment|
      sum + installment.interest
    }.round(2).to_f
  end

  # 指定日で支払い予定の遅損金を算出する
  def calc_total_late_charge(target_ymd)
    installments.inject(0) {|sum, installment|
      sum + installment.calc_late_charge(target_ymd)
    }.round(2).to_f
  end

  # 指定日時点での支払った遅損金の合計
  def calc_paid_late_charge(target_ymd)
    installments.inject(0) {|sum, installment|
      sum + installment.calc_paid_late_charge(target_ymd)
    }.round(2).to_f
  end

  # 指定日を元に遅損金を含めた支払い予定額
  def calc_total_amount(target_ymd = BusinessDay.today_ymd, is_exemption_late_charge = false)
    total = total_principal + total_interest

    if is_exemption_late_charge
      total += calc_paid_late_charge(target_ymd)
    else
      total += calc_total_late_charge(target_ymd)
    end

    total.round(2).to_f
  end

  # input_ymdが未入力も対象にした支払い予定金額(遅損金あり)
  def calc_total_amount_include_not_input_date
    include_no_input_date_installments.sum {|installment|
      installment.calc_total_amount(BusinessDay.today_ymd)
    }.round(2).to_f
  end

  # 全てのオーダーのInput Dateが未入力か？
  def all_orders_input_ymd_blank?
    not_due_yet? && orders.all?{|order| order.input_ymd.blank?}
  end

  # 全てのオーダーのInput Dateが入力済か？
  def all_orders_input_ymd_present?
    not_due_yet? && orders.all?{|order| order.input_ymd.present?}
  end

  # 1つでもInput Date未入力のオーダーがあるか？
  def any_orders_input_ymd_blank?
    not_due_yet? && orders.any?{|order| order.input_ymd.blank?}
  end

  # 1つでもInput Date入力済のオーダーがあるか？
  def any_orders_input_ymd_present?
    not_due_yet? && orders.any?{|order| order.input_ymd.present?}
  end

  # Switch申請ができるオーダー
  def can_apply_change_product_orders
    installments.map(&:order).select(&:can_apply_change_product?)
  end

  # Switch申請ができるオーダーを持っているか
  def has_can_apply_change_product_order?
    installments.map(&:order).any?(&:can_apply_change_product?)
  end

  # Switchできるオーダーを持っているか
  def has_can_change_product_order?
    installments.map(&:order).any?(&:can_change_product?)
  end

  # 15日単位の商品を持っているか？
  def has_15day_products?
    exclude_no_input_date_orders.any?{|order|
      return false if order.product.nil?

      order.product.product_key == 8
    }
  end

  # paidからステータスを戻す処理
  def rollback_paid_status
    # next_dueかnot_due_yetのみの想定
    self.status = BusinessDay.in_enable_payment(due_ymd) ? :next_due : :not_due_yet
    self.paid_up_ymd = nil
    self.paid_up_operated_ymd = nil
  end

  # フロントでの表示用のフォーマット
  def status_label
    enum_to_label('status')
  end
end
