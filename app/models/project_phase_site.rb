# == Schema Information
#
# Table name: project_phase_sites
#
#  id                   :bigint(8)        not null, primary key
#  project_phase_id     :bigint(8)        not null
#  contractor_id        :bigint(8)        not null
#  site_code            :string(255)      not null
#  site_name            :string(255)      not null
#  phase_limit          :decimal(10, 2)   not null
#  site_limit           :decimal(10, 2)   default(0.0), not null
#  paid_total_amount    :decimal(10, 2)   default(0.0)
#  refund_amount        :decimal(10, 2)   default(0.0)
#  status               :integer          default("opened"), not null
#  create_user_id       :bigint(8)        not null
#  update_user_id       :bigint(8)        not null
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

class ProjectPhaseSite < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :project_phase
  delegate :project, to: :project_phase
  belongs_to :contractor
  belongs_to :create_user, class_name: :JvUser, unscoped: true
  belongs_to :update_user, class_name: :JvUser, unscoped: true
  has_many :orders, -> { exclude_canceled.exclude_rescheduled }
  has_many :project_receive_amount_histories

  enum status: { opened: 1, closed: 2 }

  validates :contractor, uniqueness: { scope: :project_phase_id, case_sensitive: false }
  validates :site_code, presence: true
  validate :check_uniqueness_sites
  validates :site_code, uniqueness: { case_sensitive: true }
  validates :site_name, presence: true

  validates :phase_limit, presence: true
  validate  :phase_limit_validation

  validates :phase_limit, presence: true, numericality: { greater_than_or_equal_to: :site_limit },
    on: :update_site_limit

  class << self
    def search(params)
      sites = Project.find(params[:project_id]).project_phase_sites.all

      if params.dig(:search, :contractor_id).present?
        contractor_id = params.dig(:search, :contractor_id)
        sites = sites.where(contractor_id: contractor_id)
      end

      if params.dig(:search, :project_phase_id).present?
        project_phase_id = params.dig(:search, :project_phase_id)
        sites = sites.where(project_phase_id: project_phase_id)
      end

      sites.order(:project_phase_id).order(:contractor_id).includes(:project_phase).includes(:contractor)
    end

    def progress_data
      site_codes = pluck(:site_code)
      site_infos = site_codes.count > 0 ? RudyReportSaison.new(site_codes).exec : {}

      data = {}
      site_codes.each{|site_code|
        data[site_code] = site_infos[site_code]&.dig('project_complete_percent').to_f
      }

      data
    end
  end

  # Site/Orderに表示するオーダー(Input Dateなしを含む)
  def payment_list_orders
    orders.pf_appropriation_sort.eager_load(:installments)
  end

  # Input Dateのあるオーダーのみ
  def payment_list_orders_only_input_ymd
    orders.inputed_ymd.pf_appropriation_sort.eager_load(:installments)
  end

  # Orderの合計の購入金額(元本)
  def used_amount
    payment_list_orders.sum(:principal).round(2).to_f
  end

  def available_balance
    amount = (site_limit - used_amount).round(2).to_f

    # マイナスは0にする
    [amount, 0.0].max
  end

  def over_site_limit?(amount)
    # VATの分の枠を広げる
    expanded_limit_amount = site_limit * SystemSetting.credit_limit_additional_rate

    # 利用可能限度枠から残りの返済額を引く(マイナスは0にする)
    available_balance =
      [(expanded_limit_amount - used_amount).round(2), 0].max

    available_balance < amount
  end

  # TODO 仕様未確定。確認して実装する
  def paid_up_ymd
    nil
  end

  def total_principal
    orders.sum {|order| order.installments.first.principal }.round(2).to_f
  end

  def total_interest
    orders.sum {|order| order.installments.first.interest }.round(2).to_f
  end

  def calc_total_late_charge(target_ymd)
    orders.sum {|order| order.installments.first.calc_late_charge(target_ymd) }.round(2).to_f
  end

  def total_paid_principal
    orders.sum {|order| order.installments.first.paid_principal }.round(2).to_f
  end

  def total_paid_interest
    orders.sum {|order| order.installments.first.paid_interest }.round(2).to_f
  end

  def total_paid_late_charge
    orders.sum {|order| order.installments.first.paid_late_charge }.round(2).to_f
  end

  def total_repayment_amount(target_ymd)
    orders.sum {|order| order.installments.first.calc_total_amount(target_ymd) }.round(2).to_f
  end

  def paid_total_amount_with_refund
    (paid_total_amount + refund_amount).round(2).to_f
  end

  def status_label
    enum_to_label('status')
  end

  private

  # Projectじゃない方のSiteと一意チェック
  def check_uniqueness_sites
    errors.add(:site_code, :taken) if Site.exists?(site_code: site_code)
  end

  def phase_limit_validation
    # 自身を除いだC-Phase Limitの合計
    total_c_phase_limit_without_self =
      project_phase.project_phase_sites.sum(:phase_limit) - phase_limit_was.to_f

    # 新しいC-PhaseLimitの合計
    new_total_c_phase_limit = total_c_phase_limit_without_self + phase_limit.to_f

    # C-PhaseLimitの合計がPhaseLimitを超えていればエラー
    if new_total_c_phase_limit > project_phase.phase_limit
      errors.add(
        :phase_limit,
        :less_than_or_equal_to,
        count: project_phase.phase_limit - total_c_phase_limit_without_self # 登録可能な額
      )
    end
  end
end
