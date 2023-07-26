# == Schema Information
#
# Table name: contractors
#
#  id                                       :bigint(8)        not null, primary key
#  tax_id                                   :string(15)       not null
#  contractor_type                          :integer          default("normal"), not null
#  main_dealer_id                           :integer
#  use_only_credit_limit                    :boolean          default(FALSE), not null
#  application_type                         :integer          not null
#  approval_status                          :integer          not null
#  application_number                       :string(20)
#  registered_at                            :datetime
#  register_user_id                         :integer
#  enable_rudy_confirm_payment              :boolean          default(TRUE)
#  pool_amount                              :decimal(10, 2)   default(0.0), not null
#  delay_penalty_rate                       :integer          default(18), not null
#  is_switch_unavailable                    :boolean          default(FALSE), not null
#  status                                   :integer          default("active"), not null
#  exemption_late_charge_count              :integer          default(0), not null
#  project_exemption_late_charge_count      :integer          default(0), not null
#  check_payment                            :boolean          default(FALSE), not null
#  stop_payment_sms                         :boolean          default(FALSE), not null
#  notes                                    :text(65535)
#  notes_updated_at                         :datetime
#  notes_update_user_id                     :integer
#  doc_company_registration                 :boolean          default(FALSE), not null
#  doc_vat_registration                     :boolean          default(FALSE), not null
#  doc_owner_id_card                        :boolean          default(FALSE), not null
#  doc_authorized_user_id_card              :boolean          default(FALSE), not null
#  doc_bank_statement                       :boolean          default(FALSE), not null
#  doc_tax_report                           :boolean          default(FALSE), not null
#  th_company_name                          :string(100)
#  en_company_name                          :string(100)
#  address                                  :string(200)
#  phone_number                             :string(20)
#  registration_no                          :string(30)
#  establish_year                           :string(4)
#  establish_month                          :string(2)
#  employee_count                           :string(6)
#  capital_fund_mil                         :string(20)
#  shareholders_equity                      :decimal(20, 2)
#  recent_revenue                           :decimal(20, 2)
#  short_term_loan                          :decimal(20, 2)
#  long_term_loan                           :decimal(20, 2)
#  recent_profit                            :decimal(20, 2)
#  apply_from                               :string(255)
#  th_owner_name                            :string(40)
#  en_owner_name                            :string(40)
#  owner_address                            :string(200)
#  owner_sex                                :integer
#  owner_birth_ymd                          :string(8)
#  owner_personal_id                        :string(20)
#  owner_email                              :string(200)
#  owner_mobile_number                      :string(15)
#  owner_line_id                            :string(20)
#  authorized_person_same_as_owner          :boolean          default(FALSE), not null
#  authorized_person_name                   :string(40)
#  authorized_person_title_division         :string(40)
#  authorized_person_personal_id            :string(20)
#  authorized_person_email                  :string(200)
#  authorized_person_mobile_number          :string(15)
#  authorized_person_line_id                :string(20)
#  contact_person_same_as_owner             :boolean          default(FALSE), not null
#  contact_person_same_as_authorized_person :boolean          default(FALSE), not null
#  contact_person_name                      :string(40)
#  contact_person_title_division            :string(40)
#  contact_person_personal_id               :string(20)
#  contact_person_email                     :string(200)
#  contact_person_mobile_number             :string(15)
#  contact_person_line_id                   :string(20)
#  approved_at                              :datetime
#  approval_user_id                         :integer
#  update_user_id                           :integer
#  online_apply_token                       :string(30)
#  deleted                                  :integer          default(0), not null
#  rejected_at                              :datetime
#  reject_user_id                           :integer
#  created_at                               :datetime         not null
#  create_user_id                           :integer
#  updated_at                               :datetime         not null
#  operation_updated_at                     :datetime
#  qr_code_updated_at                       :datetime
#  lock_version                             :integer          default(0)
#

class Contractor < ApplicationRecord
  include ImageModule

  default_scope { where(deleted: 0) }

  belongs_to :main_dealer,   class_name: "Dealer", optional: true
  belongs_to :notes_update_user, class_name: 'JvUser', optional: true, unscoped: true
  belongs_to :update_user,   class_name: 'JvUser', optional: true, unscoped: true
  belongs_to :create_user,   class_name: 'JvUser', optional: true, unscoped: true
  belongs_to :approval_user, class_name: 'JvUser', optional: true, unscoped: true
  belongs_to :register_user, class_name: 'JvUser', optional: true, unscoped: true
  belongs_to :reject_user,   class_name: 'JvUser', optional: true, unscoped: true

  has_many :contractor_users

  # 通常のオーダー(PFオーダーを除外)
  has_many :orders, -> { where(project_phase_site_id: nil) }
  # PFも含めたオーダー
  has_many :include_pf_orders, class_name: "Order"

  has_many :installments, through: :orders
  has_many :cashback_histories
  has_many :eligibilities
  has_many :payments, -> { exclude_not_input_ymd }
  has_many :include_no_input_date_payments, class_name: "Payment"
  has_many :evidences
  has_many :receive_amount_histories
  has_many :change_product_applies
  has_many :sites
  has_many_attached :payment_images
  has_one_attached :qr_code_image

  # 申し込み書類
  has_one_attached :doc_company_certificate
  has_one_attached :doc_vat_certification
  has_one_attached :doc_office_store_map
  has_one_attached :doc_financial_statement
  has_one_attached :doc_application_form

  has_one_attached :doc_copy_of_national_id

  # オンライン申請用の本人確認画像
  has_one_attached :selfie_image
  has_one_attached :national_card_image

  has_many :scoring_results
  has_many :scoring_comments
  has_many :applied_dealers, -> { order(:sort_number) }
  has_many :available_products
  # Project
  has_many :project_phase_sites
  has_many :project_phases, through: :project_phase_sites
  has_many :projects, through: :project_phases

  has_many :delay_penalty_rate_update_histories
  has_many :contractor_billing_data

  enum application_type: { applied_online: 1, applied_paper: 2 }
  enum approval_status: { pre_registration: 1, processing: 2, qualified: 3, rejected: 4, draft: 5 }
  enum owner_sex: { male: 1, female: 2, unselected: 3 }
  enum status: { active: 1, inactive: 2 }


  # 通常登録（Draftではない）の場合の必須チェック
  with_options unless: -> { draft? } do |presence|
    presence.validates :th_company_name, presence: true
    presence.validates :en_company_name, presence: true
    presence.validates :phone_number, presence: true

    presence.validates :owner_personal_id, presence: true
    presence.validates :owner_mobile_number, presence: true
    presence.validates :th_owner_name, presence: true
    presence.validates :en_owner_name, presence: true
    presence.validates :owner_email, presence: true
  end

  validates :tax_id, presence: true, length: { is: 13 },
    numericality: { only_integer: true, allow_blank: true }

  # 既存以外は全ての tax_id に重複チェックをする
  validates :tax_id, uniqueness: { case_sensitive: false }, if: :tax_id_changed?

  validates :th_company_name, length: { maximum: 100 }
  validates :en_company_name, length: { maximum: 100 }
  validates :phone_number,    length: { maximum:  20 }

  validates :establish_year,     length: { maximum: 4 },
    numericality: { only_integer: true, allow_blank: true }

  validates :employee_count,     length: { maximum: 6 },
    numericality: { only_integer: true, allow_blank: true }

  validates :address,            length: { maximum: 200 }
  validates :registration_no,    length: { maximum: 30 }

  validates :capital_fund_mil,   length: { maximum: 20 },
    numericality: { allow_blank: true }

  validates :application_number, length: { maximum: 20 },
    uniqueness: { conditions: -> { where.not(application_number: nil) }, case_sensitive: false }

  validates :notes,              length: { maximum: 65535 }

  validates :establish_month,    length: { maximum: 2 },
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 12,
    },
    allow_blank: true

  validates :shareholders_equity, length: { maximum: 18 }, numericality: { allow_blank: true }
  validates :recent_revenue,      length: { maximum: 18 }, numericality: { allow_blank: true }
  validates :short_term_loan,     length: { maximum: 18 }, numericality: { allow_blank: true }
  validates :long_term_loan,      length: { maximum: 18 }, numericality: { allow_blank: true }
  validates :recent_profit,       length: { maximum: 18 }, numericality: { allow_blank: true }
  validates :apply_from,          length: { maximum: 255 }

  # Owner
  validates :owner_personal_id, length: { is: 13 }, if: -> { !draft? }
  validates :owner_personal_id, numericality: { only_integer: true, allow_blank: true }

  validates :owner_mobile_number, length: { maximum: 11 },
    numericality: { only_integer: true, allow_blank: true }

  validates :th_owner_name, length: { maximum: 40 }
  validates :en_owner_name, length: { maximum: 40 }
  validates :owner_email,   length: { maximum: 200 }
  validates :owner_address, length: { maximum: 200 }

  validates :owner_birth_ymd, length: { is: 8, allow_blank: true },
    numericality: { only_integer: true, allow_blank: true }

  validates :owner_line_id, length: { maximum: 20 }


  # Authorized Person
  # Name
  validates :authorized_person_name, presence: true, if: -> { !draft? && !authorized_person_same_as_owner }
  validates :authorized_person_name, length: { maximum: 40 }

  # Citizen ID
  validates :authorized_person_personal_id, length: { is: 13 }, if: -> { !draft? && !authorized_person_same_as_owner }
  validates :authorized_person_personal_id, numericality: { only_integer: true, allow_blank: true }

  # Mobile Number
  validates :authorized_person_mobile_number, presence: true, if: -> { !draft? && !authorized_person_same_as_owner }
  validates :authorized_person_mobile_number, length: { maximum: 11 },
    numericality: { only_integer: true, allow_blank: true }

  # E-Mail
  validates :authorized_person_email, presence: true, if: -> { !draft? && !authorized_person_same_as_owner }
  validates :authorized_person_email, length: { maximum: 200 }

  # AP - Option
  validates :authorized_person_title_division, length: { maximum: 40 }
  validates :authorized_person_line_id,        length: { maximum: 20 }


  # Contact Person
  # Name
  validates :contact_person_name, presence: true, if: -> { !draft? && !contact_person_same_as? }
  validates :contact_person_name, length: { maximum: 40 }

  # Citizen ID
  validates :contact_person_personal_id, length: { is: 13 }, if: -> { !draft? && !contact_person_same_as? }
  validates :contact_person_personal_id, numericality: { only_integer: true, allow_blank: true }

  # Mobile Number
  validates :contact_person_mobile_number, presence: true, if: -> { !draft? && !contact_person_same_as? }
  validates :contact_person_mobile_number, length: { maximum: 15 },
    numericality: { only_integer: true, allow_blank: true }

  # E-Mail
  validates :contact_person_email, presence: true, if: -> { !draft? && !contact_person_same_as? }
  validates :contact_person_email, length: { maximum: 200 }

  # CP - Option
  validates :contact_person_title_division, length: { maximum: 40 }
  validates :contact_person_line_id,        length: { maximum: 20 }


  # Other
  validates :delay_penalty_rate, presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # RUDYでのContractorの絞り込み
  scope :after_registration, -> {
    processing.or(qualified)
  }

  scope :in_use_order_contractor, -> {
    joins(:orders).eager_load(:orders)
      .where(orders: { paid_up_ymd: nil, canceled_at: nil })
  }
  scope :has_order_contractor, -> {
    joins(:orders).includes(:orders)
      .where(orders: { canceled_at: nil })
  }


  class << self
    # 承認前のContractorの検索
    def search_processing(params)
      relation = where.not(approval_status: [:pre_registration, :qualified])
                  .order('contractors.created_at DESC, contractors.id DESC')

      # TAX ID
      if params.dig(:search, :tax_id).present?
        tax_id   = params.dig(:search, :tax_id)
        relation = relation.where("contractors.tax_id LIKE ?", "#{tax_id}%")
      end

      # Applied Online Only
      if params.dig(:search, :applied_online_only).to_s == 'true'
        relation = relation.applied_online
      end

      # Contractor Type
      if params.dig(:search, :contractor_type).present?
        contractor_type = params.dig(:search, :contractor_type)
        relation = relation.where(contractor_type: contractor_type)
      end

      # Company Name
      if params.dig(:search, :company_name).present?
        company_name = params.dig(:search, :company_name)
        relation = relation.where("CONCAT(en_company_name, th_company_name) LIKE ?", "%#{company_name}%")
      end

      # Dealer
      if params.dig(:search, :dealer_id).present?
        dealer_id = params.dig(:search, :dealer_id)
        relation = relation.includes(:applied_dealers).where(applied_dealers: {dealer_id: dealer_id})
      end

      # Application Type
      if params.dig(:search, :application_type).present?
        application_type = params.dig(:search, :application_type)
        relation = relation.where(application_type: application_type)
      end

      # Approval Status
      if params.dig(:search, :approval_status).present?
        approval_status = params.dig(:search, :approval_status)
        relation = relation.where(approval_status: approval_status)
      end

      # Paging
      total_count = relation.count
      result = paginate(params[:page], relation, params[:per_page])

      [result, total_count]
    end

    # 承認済みのContractorの検索
    def search_qualified(params)
      relation = qualified.includes(:eligibilities, eligibilities: :dealer_type_limits)
        .where(eligibilities: {latest: true}) # dealer_typeの検索用に最新のeligibilityを取得する
        .order('contractors.id ASC')

      # TAX ID(tax_id)
      if params.dig(:search, :tax_id).present?
        tax_id = params.dig(:search, :tax_id)
        relation = relation.where("tax_id LIKE ?", "#{tax_id}%")
      end

      # Contractor Type
      if params.dig(:search, :contractor_type).present?
        contractor_type = params.dig(:search, :contractor_type)
        relation = relation.where(contractor_type: contractor_type)
      end

      # Use Only Credit Limit
      if params.dig(:search, :use_only_credit_limit).to_s == 'true'
        relation = relation.where("contractors.use_only_credit_limit = ?", true)
      end

      # Company Name(en_company_name, th_company_name)
      if params.dig(:search, :company_name).present?
        company_name = params.dig(:search, :company_name)
        relation = relation.where("CONCAT(en_company_name, th_company_name) LIKE ?", "%#{company_name}%")
      end

      # Show Only Inactive Contractor
      if params.dig(:search, :show_inactive_only).to_s == "true"
        relation = relation.where(status: :inactive)
      end

      # Dealer
      if params.dig(:search, :dealer_id).present?
        dealer_id = params.dig(:search, :dealer_id)
        relation = relation.includes(:applied_dealers).where(applied_dealers: {dealer_id: dealer_id})
      end

      # Dealer Type
      if params.dig(:search, :dealer_type).present?
        dealer_type = params.dig(:search, :dealer_type)
        relation    = relation.where(eligibilities: {dealer_type_limits: {dealer_type: dealer_type}})
      end

      # paging
      total_count = relation.count
      result      = paginate(params[:page], relation, params[:per_page])

      [result, total_count]
    end

    def search_qualified_for_dealer(params)
      relation = qualified

      # TAX ID(tax_id)
      if params.dig(:search, :tax_id).present?
        tax_id   = params.dig(:search, :tax_id)
        relation = relation.where("tax_id LIKE ?", "#{tax_id}%")
      end

      # Company Name(en_company_name, th_company_name)
      if params.dig(:search, :company_name).present?
        company_name = params.dig(:search, :company_name)
        relation = relation.where("CONCAT(en_company_name, th_company_name) LIKE ?", "%#{company_name}%")
      end

      # Show the Inactive Contractor
      if params.dig(:search, :show_inactive).to_s != "true"
        relation = relation.active
      end

      total_count = relation.count
      # sort
      relation.order('updated_at DESC')
      # paging
      result = paginate(params[:page], relation, params[:per_page])

      [result, total_count]
    end

    # over_dueのpaymentを持つContractorを取得
    def has_over_due_payment_contractors
      includes(:payments).select{ |contractor| contractor.payments.over_due.exists? }
    end

    def generate_online_apply_token
      loop do
        random_token = SecureRandom.urlsafe_base64
        break random_token unless exists?(online_apply_token: random_token)
      end
    end

    def generate_application_number
      prev_application_number = where.not(application_number: nil).maximum(:application_number)

      # 一つ前のapplication_numberから年を取得
      prev_year = prev_application_number&.match(/\d{4}/).to_s

      # 現在の年月日を取得
      current_ymd = Time.zone.now.strftime('%Y%m%d')

      # 連番の初期値
      next_number = "000000"

      # 年が同じ場合は一つ前のに +1
      if prev_year == current_ymd[0, 4]
        # 連番部分を取得
        prev_number = prev_application_number.match(/\d+$/).to_s

        # 新しい連番を取得
        next_number = format("%06d", prev_number.to_i + 1)
      end

      "OLA-#{current_ymd}-#{next_number}"
    end
  end

  ## Credit Limit
  def credit_limit_amount
    eligibilities.latest&.limit_amount.to_f
  end

  # 残りの元本返済額(Used Amount)
  def remaining_principal
    # アクティブなSiteのリミットの合計を取得
    total_site_credit_limit = sites.not_close.sum(:site_credit_limit).round(2).to_f

    # 支払い可能なSite以外のオーダー
    not_site_orders = orders.payable_orders.where(site_id: nil)

    # 支払い可能なCloseしたSiteのオーダー
    closed_site_orders = orders.payable_orders.includes(:site).where(sites: { closed: true })

    # Used Amountを取得
    target_remaining_principal =
      (not_site_orders + closed_site_orders).sum(&:remaining_principal).round(2)

    # 残りの元本返済額
    (target_remaining_principal + total_site_credit_limit).round(2).to_f
  end

  # 利用可能残金
  def available_balance
    amount = (credit_limit_amount - remaining_principal).round(2).to_f

    # マイナスは0にする
    [amount, 0.0].max
  end

  # 上限の確認
  def over_credit_limit?(amount)
    # 通常の申し込み（オンライン申し込み以外）はチェックしない
    pp "::: amount = #{amount}"
    return false unless use_only_credit_limit

    # VAT?の分の枠を広げる
    expanded_credit_limit_amount =
      BigDecimal(credit_limit_amount.to_s) * SystemSetting.credit_limit_additional_rate

    pp "::: expanded_credit_limit_amount = #{expanded_credit_limit_amount}"

    # 利用可能限度枠から残りの返済額を引く(マイナスは0にする)
    available_balance = [(expanded_credit_limit_amount - remaining_principal).round(2), 0].max

    pp "::: available_balance = #{available_balance}"

    available_balance < amount
  end


  ## Dealer Type Limit
  def latest_dealer_type_limits
    return DealerTypeLimit.none if use_only_credit_limit

    eligibilities.latest&.dealer_type_limits || DealerTypeLimit.none
  end

  def dealer_type_limit_amount(dealer_type)
    latest_dealer_type_limits.find_by(dealer_type: dealer_type)&.limit_amount.to_f
  end

  def dealer_type_remaining_principal(dealer_type)
    # orders.payable_orders.includes(:dealer)
    #   .where(dealers: {dealer_type: dealer_type}).sum(&:remaining_principal).to_f

    total_site_credit_limit = sites.includes(:dealer).where(dealers: {dealer_type: dealer_type})
      .not_close.sum(:site_credit_limit).round(2)

    # 支払い可能なCPAC以外のオーダー
    not_site_orders =
      orders.payable_orders.includes(:dealer).where(site_id: nil, dealers: {dealer_type: dealer_type})

    # 支払い可能なCloseしたCPACのオーダー
    closed_site_orders = orders.payable_orders.includes(:site, :dealer)
      .where(sites: { closed: true }, dealers: {dealer_type: dealer_type})

    # Used Amountを取得
    target_remaining_principal =
      (not_site_orders + closed_site_orders).sum(&:remaining_principal).round(2)

    # 残りの元本返済額
    (target_remaining_principal + total_site_credit_limit).round(2).to_f
  end

  def dealer_type_available_balance(dealer_type)
    amount =
      (
        dealer_type_limit_amount(dealer_type) -
        dealer_type_remaining_principal(dealer_type)
      ).round(2).to_f

    # マイナスは0にする
    dealer_type_available_balance = [amount, 0.0].max

    # AvailableBalanceを超えないように調整(再約定で超える場合あり)
    [
      dealer_type_available_balance,
      available_balance
    ].min
  end

  # subtraction_amount はrecreateで使用
  def over_dealer_type_limit?(dealer_type, amount, subtraction_amount: 0)
    # オンラインの申し込みではチェックなし
    return false if use_only_credit_limit

    pp "::: amount = #{amount}"

    dealer_type_limit_amount = dealer_type_limit_amount(dealer_type)
    dealer_type_remaining_principal = dealer_type_remaining_principal(dealer_type)

    pp "::: dealer_type_limit_amount = #{dealer_type_limit_amount}"
    pp "::: dealer_type_remaining_principal = #{dealer_type_remaining_principal}"

    expanded_credit_limit_amount =
      BigDecimal(dealer_type_limit_amount.to_s) * SystemSetting.credit_limit_additional_rate

      pp "::: expanded_credit_limit_amount = #{expanded_credit_limit_amount}"

    # recreateの場合は現在購入金額を引く
    remaining_principal = dealer_type_remaining_principal - subtraction_amount

    pp "::: remaining_principal = #{remaining_principal}"

    # 利用可能限度枠から残りの返済額を引く(マイナスは0にする)
    dealer_type_available_balance =
      [(expanded_credit_limit_amount - remaining_principal).round(2), 0].max

    pp "::: dealer_type_available_balance = #{dealer_type_available_balance}"

    dealer_type_available_balance < amount
  end


  ## Dealer Limit
  def latest_dealer_limits
    return DealerLimit.none if use_only_credit_limit

    eligibilities.latest&.dealer_limits || DealerLimit.none
  end

  def dealer_limit_amount(dealer)
    dealer_limit = latest_dealer_limits.find_by(dealer: dealer)

    dealer_limit&.limit_amount.to_f
  end

  def dealer_remaining_principal(dealer)
    # orders.payable_orders.where(dealer: dealer).sum(&:remaining_principal).to_f

    total_site_credit_limit = sites.where(dealer: dealer).not_close.sum(:site_credit_limit).round(2)

    # 支払い可能なCPAC以外のオーダー
    not_site_orders = orders.payable_orders.includes(:dealer).where(site_id: nil, dealer: dealer)

    # 支払い可能なCloseしたCPACのオーダー
    closed_site_orders = orders.payable_orders.includes(:site, :dealer)
      .where(sites: { closed: true }, dealer: dealer)

    # Used Amountを取得
    target_remaining_principal =
      (not_site_orders + closed_site_orders).sum(&:remaining_principal).round(2)

    # 残りの元本返済額
    (target_remaining_principal + total_site_credit_limit).round(2).to_f
  end

  def dealer_available_balance(dealer)
    amount = (dealer_limit_amount(dealer) - dealer_remaining_principal(dealer)).round(2).to_f

    # マイナスは0にする
    dealer_available_balance = [amount, 0.0].max

    # DealerType AvailableBalanceを超えないように調整
    [
      dealer_available_balance,
      dealer_type_available_balance(dealer.dealer_type)
    ].min
  end

  # subtraction_amount はrecreateで使用
  def over_dealer_limit?(dealer, amount, subtraction_amount: 0)
    # オンラインの申し込みではチェックなし
    pp "::: amount = #{amount}"

    return false if use_only_credit_limit

    dealer_limit_amount = dealer_limit_amount(dealer)
    dealer_remaining_principal = dealer_remaining_principal(dealer)

    pp "::: dealer_limit_amount = #{dealer_limit_amount}"
    pp "::: dealer_remaining_principal = #{dealer_remaining_principal}"

    expanded_credit_limit_amount =
      BigDecimal(dealer_limit_amount.to_s) * SystemSetting.credit_limit_additional_rate

    pp "::: expanded_credit_limit_amount = #{expanded_credit_limit_amount}"

    # recreateの場合は現在購入金額を引く
    remaining_principal = dealer_remaining_principal - subtraction_amount

    pp "::: remaining_principal = #{remaining_principal}"

    # 利用可能限度枠から残りの返済額を引く(マイナスは0にする)
    dealer_available_balance =
      [(expanded_credit_limit_amount - remaining_principal).round(2), 0].max

    pp "::: dealer_available_balance = #{dealer_available_balance}"

    dealer_available_balance < amount
  end


  # Available Settings
  def available_settings
    AvailableProduct.available_settings(self)
  end

  def available_purchase?(dealer_type, product)
    return false if product.blank?

    dealer_type = dealer_type.to_sym
    product_key = product.product_key

    available_settings[:purchase][:dealer_type][dealer_type][:product_key][product_key][:available]
  end

  def available_switch?(dealer, product)
    return false if is_switch_unavailable || dealer.blank? || product.blank?

    dealer_type = dealer.dealer_type.to_sym
    product_key = product.product_key

    available_settings[:switch][:dealer_type][dealer_type][:product_key][product_key][:available]
  end

  def available_cashback?(dealer)
    return false if dealer.nil?

    dealer_type = dealer.dealer_type.to_sym

    available_settings[:cashback][:dealer_type][dealer_type][:available]
  end


  # paymentsに使用されるcashbackとexceededを返却する(Hash形式)
  def calc_payment_subtractions
    CalcPaymentSubtractions.new(self).call
  end

  # 遅延しているPaymentの支払い残金の合計(cashbackとexceededを減算して計算)
  def calc_over_due_amount
    payment_subtractions = calc_payment_subtractions

    calced_payments = payments.over_due.inject(0) do |sum, payment|
      sum + payment.remaining_balance - payment_subtractions[payment.id][:total]
    end

    calced_payments.round(2).to_f
  end

  # 遅損金を含めた、支払い可能な支払い残金
  def remaining_balance
    payments.appropriate_payments.sum(&:remaining_balance).round(2).to_f
  end

  def remining_balance_with_subtraction(payment)
    payment_subtractions = calc_payment_subtractions
    payment_total_subtraction = payment_subtractions[payment.id][:total]

    (payment.remaining_balance - payment_total_subtraction).round(2)
  end

  def class_type_label
    eligibilities.latest&.class_type_label
  end

  def latest_cashback
    cashback_histories&.latest
  end

  # キャッシュバックのトータル
  def cashback_amount
    latest_cashback&.total.to_f
  end

  def exceeded_amount
    pool_amount.to_f
  end

  def latest_evidence
    evidences.order(created_at: :desc).first
  end

  # 獲得キャッシュバック履歴を作成する
  def create_gain_cashback_history(amount, exec_ymd, order_id, receive_amount_history_id: nil, notes: nil)
    ActiveRecord::Base.transaction do
      # 現在の最新のcashbackを過去へ
      prev_cashback = latest_cashback
      prev_cashback&.update!(latest: false)

      notes = notes.nil? ? 'Earned Cashback' : notes

      # 最新のキャッシュバックを作成
      cashback_histories.create!(
        point_type:      'gain',
        cashback_amount: amount,
        latest:          true,
        total:           (prev_cashback&.total.to_f + amount).round(2),
        exec_ymd:        exec_ymd,
        notes:           notes,
        order_id:        order_id,
        receive_amount_history_id: receive_amount_history_id,
      )
    end
  end

  # 使用キャッシュバック履歴を作成する
  def create_use_cashback_history(amount, exec_ymd, receive_amount_history_id: nil, notes: nil)
    ActiveRecord::Base.transaction do
      # 現在の最新のcashbackを過去へ
      prev_cashback = latest_cashback
      prev_cashback.update!(latest: false)

      notes = notes.nil? ? 'Used Cashback' : notes

      # 最新のキャッシュバックを作成
      cashback_histories.create!(
        point_type:      'use',
        cashback_amount: amount,
        latest:          true,
        total:           (prev_cashback.total - amount).round(2),
        exec_ymd:        exec_ymd,
        notes:           notes,
        receive_amount_history_id: receive_amount_history_id,
      )
    end
  end

  # TODO 不要なら削除する
  def create_eligibility(limit_amount, class_type, comment, login_user)
    errors = []

    transaction do
      eligibilities.latest.update!(latest: false) if eligibilities.latest.present?

      eligibility = eligibilities.build(
        limit_amount: limit_amount,
        class_type: class_type,
        comment: comment
      )
      eligibility.create_user = login_user

      if eligibility.save
        errors = []
      else
        errors = eligibility.error_messages
        raise ActiveRecord::Rollback
      end
    end

    errors
  end

  def set_values_for_register(create_user)
    self.create_user      = create_user
    self.update_user      = create_user
    self.register_user    = create_user
    self.registered_at    = Time.zone.now
    self.approval_status  = 'processing'
    self.application_type = 'applied_paper'
  end


  def application_type_label
    enum_to_label('application_type')
  end

  def approval_status_label
    enum_to_label('approval_status')
  end

  def status_label
    enum_to_label('status')
  end

  def owner_sex_label
    enum_to_label('owner_sex')
  end

  def contractor_type_label
    enum_to_label('contractor_type')
  end

  def evidence_uploaded_at
    check_payment ? latest_evidence.created_at : nil
  end

  # TOP画面に表示する日付。基本的には次のPaymentの約定日を表示する
  def cashback_use_ymd
    # キャッシュバックがない
    return nil if cashback_amount == 0

    # 支払い期日が確定しているPaymentを取得
    next_payments = payments.where(status: %W(over_due next_due not_due_yet))

    # 支払うPaymentがない
    return nil if next_payments.count == 0

    # キャッシュバックが直近の支払いで獲得していた場合はそのPaymentでは使用できないのでnilを返す
    gain_latest = cashback_histories.gain_latest
    return nil if gain_latest.order_id && gain_latest.payment == next_payments.first

    next_payments.first.due_ymd
  end

  # 次の支払日のPayment(未確定も含む)を取得
  def next_payment
    # 約定日が一番近いものを取得(Orderのinput_ymdがないものは除外する)
    payments.where(status: %W(next_due not_due_yet)).first
  end

  # 支払い済みで遅延のあったPaymentの件数
  def paid_over_due_payment_count
    payments.paid_over_due_payments.count
  end

  def update_available_products(available_products_params)
    # 既存のデータを全て削除してから作り直す
    available_products.destroy_all

    create_purchase = !(available_products_params[:purchase_use_global].to_s == 'true')
    create_switch   = !(available_products_params[:switch_use_global].to_s == 'true')
    create_cashback = !(available_products_params[:cashback_use_global].to_s == 'true')

    purchase = available_products_params[:purchase]
    switch   = available_products_params[:switch]
    cashback = available_products_params[:cashback]

    ApplicationRecord.dealer_types.keys.each do |dealer_type|
      # Purchaseの作成
      if create_purchase
        product_checkbox_data = purchase[dealer_type.to_sym]
        product_checkbox_data.each do |data|
          product_key = data[:product_key]
          available = data[:available]

          available_products.create!(
            category: :purchase,
            product: Product.find_by!(product_key: product_key),
            dealer_type: dealer_type,
            available: available,
          )
        end
      end

      # Switchの作成
      if create_switch
        product_checkbox_data = switch[dealer_type.to_sym]
        product_checkbox_data.each do |data|
          product_key = data[:product_key]
          available = data[:available]

          available_products.create!(
            category: :switch,
            product: Product.find_by!(product_key: product_key),
            dealer_type: dealer_type,
            available: available,
          )
        end
      end

      # Cashbackの作成
      if create_cashback
        available_products.create!(
          category: :cashback,
          product: Product.find_by!(product_key: 1),
          dealer_type: dealer_type,
          available: cashback[dealer_type.to_sym],
        )
      end
    end
  end

  # 変更可能な商品のリスト。利用可能なDealerTypeで１つでも商品が利用可能なら対象になる
  def allowed_change_products(target_dealer_type = nil)
    # 利用不可は空を返す
    return Product.none if is_switch_unavailable

    target_product_keys = []

    # TODO 修正する
    available_settings[:switch][:dealer_type].each do |dealer_type, products|
      # dealer_typeの指定がある場合はそのdealer_typeのみを対象にする
      next if target_dealer_type.present? && target_dealer_type.to_sym != dealer_type

      products[:product_key].each do |product_key, settings|
        if settings[:available]
          target_product_keys.push(product_key)
        end
      end
    end

    Product.where(product_key: target_product_keys.uniq)
  end

  # 消し込み可能かつ商品変更の申請をされているオーダーがあるかの判定
  def has_can_repayment_and_applying_change_product_orders?
    # 消し込み可能なpaymentを対象に、商品変更の申請があるオーダーの存在をチェック
    payments.appropriate_payments.any? do |payment|
      payment.orders.exists?(is_applying_change_product: true)
    end
  end

  # Contractor Userの規約同意バージョンをリセットする
  def reset_agreed_terms_of_service_version
    contractor_users.update_all(terms_of_service_version: 0)
  end

  # Dealer Type Limitが設定されているDealer Types
  def enabled_limit_dealer_types
    return ApplicationRecord.dealer_types.keys.map(&:to_sym) if use_only_credit_limit

    return [] if eligibilities.blank?

    eligibilities.latest.dealer_type_limits.pluck(:dealer_type).map(&:to_sym)
  end

  def update_applied_dealers(applied_dealers_params)
    applied_dealers.destroy_all

    applied_dealers_params.each.with_index(1) do |param, idx|
      applied_dealers.create!(
        dealer_id: param[:dealer_id],
        applied_ymd: param[:applied_ymd],
        sort_number: idx
      )
    end
  end

  # DealerLimit, DealerTypeLimitの両方が設定されているかの判定
  def dealer_without_limit_setting?(dealer)
    # オンライン申し込みは設定ずみとみなす
    return true if use_only_credit_limit

    # DealerTypeLimit設定のチェック
    return false if !enabled_limit_dealer_types.include?(dealer.dealer_type.to_sym)

    # DealerLimit設定のチェック
    latest_dealer_limits.pluck(:dealer_id).include?(dealer.id)
  end

  # RUDY API用
  def available_dealer_codes
    if use_only_credit_limit
      # 全てのDealerからAvailableSettingで絞る
      return Dealer.all.select{|dealer|
        available_any_purchase?(dealer.dealer_type)
      }.pluck(:dealer_code)
    end

    # Limitが設定されているDealerTypeの中から購入が許可されているDealerTypeを取得する
    available_dealer_types = enabled_limit_dealer_types.select do |dealer_type|
      available_any_purchase?(dealer_type)
    end

    # 購入が可能なDealerLimitを取得
    available_dealer_limits =
      latest_dealer_limits.includes(:dealer).where(dealers: {dealer_type: available_dealer_types})

    # DealerLimitからDealer Codeを取得
    available_dealer_limits.map do |dealer_limit|
      dealer_limit.dealer.dealer_code
    end
  end

  # DealerTypeを指定して１つでも購入できる商品があるかの判定
  def available_any_purchase?(dealer_type)
    available_settings[:purchase][:dealer_type][dealer_type.to_sym][:product_key].values.any? do |value|
      value[:available]
    end
  end

  def update_delay_penalty_rate(new_rate, user)
    errors = []

    ActiveRecord::Base.transaction do
      # 更新履歴の作成
      delay_penalty_rate_update_histories.create!(
        old_rate: delay_penalty_rate,
        new_rate: new_rate,
        update_user: user
      )

      unless update(delay_penalty_rate: new_rate)
        errors = error_messages

        raise ActiveRecord::Rollback
      end
    end

    return errors
  end

  def attach_documents(document_params)
    # Company書類
    company_certificate = document_params[:company_certificate]
    vat_certification   = document_params[:vat_certification]
    office_store_map    = document_params[:office_store_map]
    financial_statement = document_params[:financial_statement]
    application_form    = document_params[:application_form]
    copy_of_national_id = document_params[:copy_of_national_id]

    # Owner書類
    selfie_image_file        = document_params[:selfie_image]
    national_card_image_file = document_params[:card_image]

    # Company書類のアタッチ
    attach_document(doc_company_certificate, company_certificate)
    attach_document(doc_vat_certification, vat_certification)
    attach_document(doc_office_store_map, office_store_map)
    attach_document(doc_financial_statement, financial_statement)
    attach_document(doc_application_form, application_form)
    attach_document(doc_copy_of_national_id, copy_of_national_id)

    # Owner書類のアタッチ
    attach_document(selfie_image, selfie_image_file)
    attach_document(national_card_image, national_card_image_file)
  end

  def sms_servcie_name
    main_dealer ? main_dealer.dealer_type_setting.sms_servcie_name : "SAISON CREDIT"
  end

  private
    def attach_document(target, file)
      return if file.blank?

      data = file.fetch(:data)
      filename = file.fetch(:filename)

      target.attach(io: parse_base64(data), filename: filename)
    end

    def contact_person_same_as?
      contact_person_same_as_owner || contact_person_same_as_authorized_person
    end
end
