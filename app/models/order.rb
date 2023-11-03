# frozen_string_literal: true
# == Schema Information
#
# Table name: orders
#
#  id                             :bigint(8)        not null, primary key
#  order_number                   :string(255)      not null
#  contractor_id                  :integer          not null
#  dealer_id                      :integer
#  second_dealer_id               :bigint(8)
#  site_id                        :integer
#  project_phase_site_id          :bigint(8)
#  order_type                     :string(30)
#  product_id                     :integer
#  bill_date                      :string(15)       default(""), not null
#  rescheduled_new_order_id       :integer
#  rescheduled_fee_order_id       :integer
#  rescheduled_user_id            :integer
#  rescheduled_at                 :datetime
#  fee_order                      :boolean          default(FALSE)
#  installment_count              :integer          not null
#  purchase_ymd                   :string(8)        not null
#  purchase_amount                :decimal(10, 2)   not null
#  amount_without_tax             :decimal(10, 2)
#  second_dealer_amount           :decimal(10, 2)
#  paid_up_ymd                    :string(8)
#  input_ymd                      :string(8)
#  input_ymd_updated_at           :datetime
#  change_product_status          :integer          default("unapply"), not null
#  is_applying_change_product     :boolean          default(FALSE), not null
#  applied_change_product_id      :integer
#  change_product_memo            :string(200)
#  change_product_before_due_ymd  :string(8)
#  change_product_applied_at      :datetime
#  product_changed_at             :datetime
#  product_changed_user_id        :integer
#  change_product_applied_user_id :integer
#  change_product_apply_id        :integer
#  region                         :string(50)
#  order_user_id                  :integer
#  canceled_at                    :datetime
#  canceled_user_id               :integer
#  rudy_purchase_ymd              :string(8)
#  uniq_check_flg                 :boolean          default(TRUE)
#  deleted                        :integer          default(0), not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  operation_updated_at           :datetime
#  lock_version                   :integer          default(0)
#

class Order < ApplicationRecord
  include DealerPaymentModule

  attr_accessor :reschedule_product, :is_second_dealer

  # 運用対応でdeleted: 1があるので注意
  default_scope { where(deleted: 0) }

  belongs_to :contractor
  belongs_to :dealer, optional: true
  belongs_to :product, optional: true
  belongs_to :site, optional: true
  belongs_to :second_dealer, class_name: :Dealer, optional: true
  # Project
  belongs_to :project_phase_site, optional: true
  delegate :project_phase, to: :project_phase_site
  delegate :project, to: :project_phase
  # Switch Product
  belongs_to :applied_change_product, class_name: :Product, optional: true
  belongs_to :change_product_apply, optional: true
  # xxx_user
  belongs_to :order_user, class_name: :ContractorUser, optional: true, unscoped: true
  belongs_to :canceled_user, class_name: :JvUser, optional: true, unscoped: true
  belongs_to :change_product_applied_user, class_name: :ContractorUser, optional: true, unscoped: true
  belongs_to :product_changed_user, class_name: :JvUser, optional: true, unscoped: true
  belongs_to :rescheduled_user, class_name: :JvUser, optional: true, unscoped: true

  has_many :installments
  has_many :payments, through: :installments
  has_many :cashback_histories
  belongs_to :rescheduled_new_order, class_name: :Order, optional: true
  belongs_to :rescheduled_fee_order, class_name: :Order, optional: true
  # has_many :rescheduled_old_orders 分岐があるのでインスタンスメソッドで実装

  enum change_product_status: { unapply: 1, applied: 2, approval: 3, rejected: 4, registered: 5 }

  validates :order_number,
            presence: true,
            uniqueness: {
              scope: [:dealer_id, :bill_date, :site_id],
              conditions: -> { where(deleted: 0).exclude_canceled },
              case_sensitive: false
            }

  validates :purchase_ymd,
            presence: true,
            length: { is: 8 }

  validates :purchase_amount,
            presence:     true,
            numericality: { greater_than_or_equal_to: 1.0 }

  validates :change_product_memo,
            length: { maximum: 200 }

  validates :order_type,
            length: { maximum: 30 }

  validates :region,
            length: { maximum: 50 }

  validates :site_id, absence: true, if: -> { project_phase_site_id.present? }
  validates :project_phase_site_id, absence: true, if: -> { site_id.present? }


  scope :exclude_canceled, -> { where(canceled_at: nil) }
  scope :exclude_rescheduled, -> { where(rescheduled_new_order_id: nil) }
  scope :inputed_ymd, -> { where.not(input_ymd: nil) }
  scope :not_input_ymd, -> { where(input_ymd: nil) }
  scope :not_paid_up, -> { where(paid_up_ymd: nil) }
  scope :not_fee_orders, -> { where(fee_order: false) }
  # 支払い可能なオーダー(キャンセルを除外、リスケを除外、未完済であること)
  scope :payable_orders, -> { exclude_canceled.exclude_rescheduled.not_paid_up }
  # リスケされた新しいオーダー
  scope :rescheduled_new_orders, -> { where.not(rescheduled_at: nil) }
  # リスケされていないオーダー
  scope :not_rescheduled_new_orders, -> { where(rescheduled_at: nil) }
  # 商品の変更可能なオーダー
  scope :can_change_product_orders, -> { payable_orders.not_rescheduled_new_orders }
  # 請求の対象
  scope :payment_target_orders,
    -> (input_ymd){
      inputed_ymd.not_rescheduled_new_orders.exclude_canceled.where(input_ymd: input_ymd)
    }

  # PFで表示・充当をしていく順番
  scope :pf_appropriation_sort, -> {
    order(
      'due_ymd ASC, orders.input_ymd ASC, orders.purchase_ymd ASC, orders.created_at ASC, orders.id'
    )
  }

  class << self
    def generate_reschedule_order_number
      today_ymd = BusinessDay.today_ymd

      new_order_plefix = 'RS'
      fee_order_plefix = 'RF'

      # 今日日付で連番が一番大きい order_number を取得
      latest_order_number =
        rescheduled_new_orders
          .where("order_number LIKE ?", "#{new_order_plefix}#{today_ymd}%")
          .order(order_number: :desc).first&.order_number

      # 連番部分を取得
      new_number =
        if latest_order_number.present?
          # 既存があれば、最新の連番に１を足す
          number = latest_order_number[-4, 4].to_i + 1
          format('%04d', number)
        else
          # 既存がなければ、今日付の最初の連番を作成
          "0001"
        end

      raise '連番の上限超過' if new_number.length > 4

      # RS202005010001
      # RF202005010001
      [
        "#{new_order_plefix}#{today_ymd}#{new_number}",
        "#{fee_order_plefix}#{today_ymd}#{new_number}",
      ]
    end

    def remaining_principal
      all.sum do |order|
        order.remaining_principal
      end.round(2)
    end

    def remaining_interest
      all.sum do |order|
        order.remaining_interest
      end.round(2)
    end

    def calc_remaining_late_charge(target_ymd)
      all.sum do |order|
        order.calc_remaining_late_charge(target_ymd)
      end.round(2)
    end

    def calc_remaining_interest_and_late_charge(target_ymd)
      (remaining_interest + calc_remaining_late_charge(target_ymd)).round(2)
    end

    def calc_remaining_balance(target_ymd)
      all.sum do |order|
        order.calc_remaining_balance(target_ymd)
      end.round(2)
    end

    def calc_remainings(target_ymd)
      {
        principal:   remaining_principal,
        interest:    remaining_interest,
        late_charge: calc_remaining_late_charge(target_ymd),
        interest_and_late_charge: calc_remaining_interest_and_late_charge(target_ymd),
        total_balance: calc_remaining_balance(target_ymd),
      }
    end

    def paging(params)
      relation = self.all # paginate用にActiveRecord::Relation形式にする
      total_count = relation.count

      if params[:page].present? && params[:per_page].present?
        relation = paginate(params[:page], relation, params[:per_page])
      end

      [relation, total_count]
    end

    def search(params)
      relation =
        all.eager_load(:contractor, :dealer, :site, :project_phase_site, :rescheduled_new_order)
        .order(is_applying_change_product: :DESC, purchase_ymd: :DESC, created_at: :DESC, id: :DESC)

      # Order Number
      if params.dig(:search, :order_number).present?
        order_number = params.dig(:search, :order_number)
        relation = relation.where("orders.order_number LIKE ?", "#{order_number}%")
      end

      # Site Code
      if params.dig(:search, :site_code).present?
        site_code = params.dig(:search, :site_code)
        relation =
          relation.where("sites.site_code LIKE ?", "#{site_code}%")
          .or(relation.where("project_phase_sites.site_code LIKE ?", "#{site_code}%"))
      end

      # Purchase Date(purchase_ymd)
      if params.dig(:search, :purchase).present?
        purchase = params.dig(:search, :purchase)
        from_ymd = purchase[:from_ymd].presence || "00000000"
        to_ymd   = purchase[:to_ymd].presence || "99999999"

        relation = relation.where(purchase_ymd: from_ymd..to_ymd)
      end

      # Include No Input Date
      if params.dig(:search, :include_no_input_date).to_s != 'true'
        relation = relation.where.not(input_ymd: nil)
      end

      # TAX ID(tax_id)
      if params.dig(:search, :tax_id).present?
        tax_id   = params.dig(:search, :tax_id)
        relation = relation.where("contractors.tax_id LIKE ?", "#{tax_id}%")
      end

      # Contractor Type
      if params.dig(:search, :contractor_type).present?
        contractor_type = params.dig(:search, :contractor_type)
        relation  = relation.where(contractors: { contractor_type: contractor_type })
      end

      # Company Name
      if params.dig(:search, :company_name).present?
        company_name = params.dig(:search, :company_name)
        relation     = relation.where("CONCAT(en_company_name, th_company_name) LIKE ?", "%#{company_name}%")
      end

      # Dealer
      if params.dig(:search, :dealer_id).present?
        dealer_id = params.dig(:search, :dealer_id)
        relation  = relation.where(dealer_id: dealer_id)
      end

      # Dealer Type
      # TODO ロジックをチェックする
      if params.dig(:search, :dealer_type).present?
        dealer_type = params.dig(:search, :dealer_type)
        relation  = relation.where("dealers.dealer_type = ?", Dealer.dealer_types[dealer_type])
      end

      # Include Paid Up Date
      if params.dig(:search, :include_paid_up).to_s != 'true'
        relation = relation.not_paid_up
      end

      # Include Canceled
      if params.dig(:search, :include_canceled).to_s != 'true'
        relation = relation.exclude_canceled
      end

      # Include Rescheduled
      if params.dig(:search, :include_rescheduled).to_s != 'true'
        relation = relation.exclude_rescheduled
      end

      # Paging
      if params[:page].present? && params[:per_page].present?
        result = paginate(params[:page], relation, params[:per_page])
      else
        result = relation
      end

      [result, relation.count]
    end

    # Order Basis CSV の対象データ
    def order_basis_data
      installments = Installment.unscope(where: :deleted).includes([:exemption_late_charges, order:
        [:product, :contractor, :dealer, :second_dealer, :rescheduled_new_order, :site, project_phase_site:
        [project_phase: :project]]])
        .where.not(orders: { input_ymd: nil })
        .where.not(orders: { deleted: 1 })
        .order('orders.purchase_ymd desc, orders.created_at desc, orders.id desc, ' +
          'installments.installment_number asc, installments.created_at asc')

      # Indexの付与を判定する変数
      installment_index = nil
      prev_order_id = nil

      # キャンセルでdeletedになったinstallmentは取得し、Switchでdeletedになったinstallmentは除外する
      # 現状では判定するカラムがないのでOrderの値とInstallmentの並び順で判定する
      filtered_installments = installments.map do |installment|
        # OrderごとにInstallmentのindexをつける
        if prev_order_id != installment.order_id
          # 前のOrderIDと異なる場合は新しいOrderIDを保持・Installment Indexを初期化する
          prev_order_id = installment.order_id
          installment_index = 1
        else
          # 前と同じOrderIDならIndexを１つ増やす
          installment_index += 1
        end

        order = installment.order
        if order.canceled?
          # キャンセルされている場合はSwitchで変更前のdeletedなinstallmentも取得されるので、
          # 有効なキャンセルされたinstallmentのみを取得する

          # 削除したinstallmentの件数を取得(キャンセル済みは全てdeletedの想定)
          deleted_installment_count = order.installments.unscope(where: :deleted).count

          # order.installment_countよりdeleted_installment_countが多ければ、
          # Switch後にキャンセルされている(deleted_installmentにSwitchとキャンセルでdeletedになったinstallmentが含まれている)
          # order.installment_countはSwitch後のinstallmentの件数を保持している
          if deleted_installment_count > order.installment_count
            # Switchでdeletedになったinstallmentの件数を取得(現状は必ず1の想定)
            exclude_first_limit_count = deleted_installment_count - order.installment_count

            # Switchとキャンセルでdeletedになったinstallmentの並び順はSwitch -> キャンセルになるので、
            # Switchでdeletedになったinstallmentのみをnextでスキップする
            next if installment_index <= exclude_first_limit_count
          end

        else
          # キャンセル以外のdeletedは全て除外する
          next if installment.deleted?
        end

        installment
      end

      filtered_installments.compact
    end
  end

  def rescheduled_old_orders
    fee_order ? Order.where(rescheduled_fee_order_id: id) : Order.where(rescheduled_new_order_id: id)
  end

  # リスケされた新しいオーダーかの判定
  def rescheduled_new_order?
    rescheduled_at.present?
  end

  # リスケされた古いオーダーかの判定
  def rescheduled?
    rescheduled_new_order_id.present?
  end

  def can_reschedule?
    !rescheduled? && # ยังไม่ได้ทำสัญญาซ้ำอีกครั้ง
    !is_applying_change_product # ไม่อยู่ในขั้นตอนการขอเปลี่ยนสินค้า
  end

  def canceled?
    canceled_at.present?
  end

  # ローン変更申請のステータスの定数とラベルのセット
  def change_product_status_label
    enum_to_label('change_product_status')
  end

  # 締め日に、次の締め日で約定日を算出して更新する
  def update_due_ymd
    raise 'input_ymdが入力済み' if input_ymd.present?

    # 次の締め日を算出
    next_closing_date =
      if BusinessDay.today.day == SystemSetting.closing_day
        # 締め日が15日の場合は、月末の締め日を取得
        BusinessDay.today.end_of_month
      else
        # 締め日が月末の場合は、翌月の締め日(15日)を取得
        tomorrow = BusinessDay.tomorrow
        Date.new(tomorrow.year, tomorrow.month, SystemSetting.closing_day)
      end

    # ymd形式へ
    next_closing_ymd = next_closing_date.strftime(ymd_format)

    # 新しい締め日の約定日を取得
    due_ymds = product.calc_due_ymds(next_closing_ymd)

    installments.each do |installment|
      # ลบการผ่อนชำระออกจากการชำระเงินที่เป็นของ
      installment.remove_from_payment

      # 新しい約定日
      next_due_ymd = due_ymds[installment.installment_number]

      if project_phase_site.present?
        # PFはPaymentに紐づかないので nil を設定
        next_due_payment = nil
      else
        # 新しい約定日のPayment
        next_due_payment = Payment.find_or_initialize_by(
          contractor: contractor,
          due_ymd:    next_due_ymd,
          status:     'not_due_yet'
        )

        # 新しい約定日のPaymentに支払い金額を追加
        next_due_payment.total_amount += installment.total_amount

        next_due_payment.save!
      end

      installment.update!(payment: next_due_payment, due_ymd: next_due_ymd)
    end
  end

  # 支払い予定金額の合計(遅損金なし)
  def total_amount
    installments.inject(0) {|sum, installment|
      sum + installment.total_amount
    }.round(2).to_f
  end

  # 支払い予定金額の合計(遅損金あり)
  def calc_total_amount(target_ymd = BusinessDay.today_ymd)
    installments.inject(0) {|sum, installment|
      sum + installment.calc_total_amount(target_ymd)
    }.round(2).to_f
  end

  # 支払った金額の合計
  def paid_total_amount
    installments.inject(0) {|sum, installment|
      sum + installment.paid_total_amount
    }.round(2).to_f
  end

  # 残りの元本
  def remaining_principal
    installments.remaining_principal
  end

  # 残りの利子
  def remaining_interest
    installments.remaining_interest
  end

  # TODO installmentでリスケを考慮していないので要確認
  def calc_remaining_late_charge(target_ymd = BusinessDay.today_ymd)
    installments.inject(0) {|sum, installment|
      sum + installment.calc_remaining_late_charge(target_ymd)
    }.round(2).to_f
  end

  # 残りの支払額(遅損金を含む)
  def calc_remaining_balance(target_ymd)
    installments.inject(0) {|sum, installment|
      sum + installment.remaining_balance(target_ymd)
    }.round(2).to_f
  end

  # キャッシュバック金額を算出
  def calc_cashback_amount
    cashback_rate = 0.005
    # cashback_rate = 0.10

    # input_ymdが2022-01-01以降は vat_amountを含む金額(購入金額)で計算する
    amount = input_ymd >= '20220101' ? calc_purchase_amount : purchase_amount_without_vat

    # pp "::: cashback return amount = #{amount}"
    # pp "::: gain = #{(BigDecimal(amount.to_s) * cashback_rate).floor(2).to_f}"

    # VATを除いた購入金額 * 0.005 (0.5 %) 数点第三位以下切捨て
    (BigDecimal(amount.to_s) * cashback_rate).floor(2).to_f
  end

  def cut_off_ymd
    # input_ymdの3日後
    Date.parse(input_ymd).since(3.days).strftime(ymd_format)
  end

  # キャッシュバックを取得できる条件を満たしているか？
  def can_gain_cashback?
    # 再約定したオーダーはDealer(DealerType)を持たず設定を取得できないのでキャッシュバック対象外
    return false if rescheduled_new_order?
    return false if !contractor.available_cashback?(dealer)
    return false if paid_up_ymd.blank?

    # 条件１：一回払い(30日)の商品であること
    valid_product = product.product_key == 1

    # 条件２：支払完了日が、キャッシュバック獲得期日以内
    # (installmentsは1つの想定なので、その約定日を取得する)
    paid_up_in_limit = paid_up_ymd <= installments.last.due_ymd

    # キャッシュバックが付く条件
    valid_product && paid_up_in_limit
  end

  # Contractor用。ローン変更期限(約定日の３日前)を過ぎているかの判定
  def over_apply_change_product_limit_date?
    # 申請可能期日を取得
    limit_date = apply_change_product_limit_date(first_due_ymd)

    return limit_date < BusinessDay.today
  end

  # Switch申請の期日
  def apply_change_product_limit_date(due_ymd)
    due_date = Date.parse(due_ymd)

    # 自動承認の場合は約定日が期限
    if dealer.dealer_type_setting.switch_auto_approval
      due_date
    else
      # 手動承認は3営業日前が期限
      BusinessDay.three_business_days_ago(due_date)
    end
  end

  # Contractor用。申請ができない理由を返す
  def apply_change_product_errors
    errors = []

    # 期限切れ
    if over_apply_change_product_limit_date?
      errors.push(I18n.t("error_message.over_apply_change_product_limit_date"))
    end

    # 一部が支払済
    if paid_total_amount > 0
      errors.push(I18n.t("error_message.some_amount_has_already_been_paid"))
    end

    errors
  end

  # Contractor用。ローン変更を申請できるかの判定
  def can_apply_change_product?
    # 一括からのみ
    return false if product.blank? || product.product_key != 1
    # キャンセルされていないこと
    return false if canceled?
    # リスケされていないこと
    return false if rescheduled?
    # リスケされたオーダーではないこと
    return false if rescheduled_new_order?
    # orderの一部(installment)が支払い済みでないこと
    return false if paid_total_amount > 0
    # 申請可能な期日を過ぎていないこと
    return false if over_apply_change_product_limit_date?
    # 未申請のみ
    return false if !unapply?
    # 変更が許可されている商品があること
    return false if contractor.allowed_change_products(dealer.dealer_type).blank?

    true
  end

  # JV用。Changeボタンを押下できるかの判定(ダイアログを表示できるかどうか)
  def can_get_change_product_schedule?
    # Switch後に状態を見れるようになるべく押せるようにする

    return false if rescheduled_new_order? # 再約定オーダーはswitch不可
    return false if unapply? && product.product_key != 1
    return false if unapply? && canceled?

    true
  end

  # JV用。Change Productができない理由を返す
  def change_product_errors
    errors = []

    # 承認・否認後はエラーメッセージは表示しない
    return [] if approval? || rejected? || registered?

    # 一部が支払済
    if paid_total_amount > 0
      errors.push(I18n.t("error_message.some_amount_has_already_been_paid"))
    end

    # input date が未入力
    if input_ymd.blank?
      errors.push(I18n.t("error_message.no_input_date"))
    end

    # 許可されていない
    if contractor.allowed_change_products.blank?
      errors.push(I18n.t("error_message.change_product_not_allow"))
    end

    errors
  end

  # JV用。ローンを変更できるかの判定
  def can_change_product?
    # 今の返済回数が１回のみ
    return false if product.blank? || product.product_key != 1
    # Input Date があること
    return false if input_ymd.blank?
    # ステータス
    return false if approval? || rejected? || registered?
    # キャンセルされている
    return false if canceled?
    # リスケ済みの古いオーダーでないこと
    return false if rescheduled?
    # リスケした新しいオーダーでないこと
    return false if rescheduled_new_order?
    # orderの一部(installment)が支払い済み
    return false if paid_total_amount > 0
    # 変更を許可している商品があること
    return false if contractor.allowed_change_products(dealer.dealer_type).blank?

    true
  end

  # JV用。(申請なし)ローン変更の登録可能判定
  def can_register_change_product?(new_product)
    # 申請されていないこと
    !is_applying_change_product &&
    # 変更を許可されている商品であること
    contractor.available_switch?(dealer, new_product) &&
    # 変更できる条件を満たしていること
    can_change_product?
  end

  # JV用。ローン変更の申請を承認できるかの判定
  def can_approval_change_product?
    # 申請されていること
    is_applying_change_product &&
    # 申請された商品が変更を許可されていること
    contractor.available_switch?(dealer, applied_change_product) &&
    # 変更できる条件を満たしていること
    can_change_product?
  end

  def first_due_ymd
    installments.find_by(installment_number: 1).due_ymd
  end

  # ローン変更スケジュールのBeforeに表示する日付(ローン変更前の約定日)
  def change_product_first_due_ymd
    change_product_before_due_ymd || first_due_ymd
  end

  # ローンを変更したかの判定
  def product_changed?
    # 承認済み、もしくは変更の登録済み
    approval? || registered?
  end

  def has_original_orders?
    rescheduled_old_orders.present?
  end

  def site_order?
    site.present?
  end

  def first_dealer_amount
    (purchase_amount - second_dealer_amount).round(2)
  end

  def belongs_to_project_finance?
    project_phase_site_id.present?
  end

  # SiteかProjectPhaseSiteを取得する
  def any_site
    return site if site_order?
    return project_phase_site if belongs_to_project_finance?
    nil
  end
end
