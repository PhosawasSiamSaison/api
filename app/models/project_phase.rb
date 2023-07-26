# == Schema Information
#
# Table name: project_phases
#
#  id                   :bigint(8)        not null, primary key
#  project_id           :bigint(8)        not null
#  phase_number         :integer          not null
#  phase_name           :string(255)      not null
#  phase_value          :decimal(10, 2)   not null
#  phase_limit          :decimal(10, 2)   default(0.0)
#  start_ymd            :string(8)        not null
#  finish_ymd           :string(8)        not null
#  due_ymd              :string(8)        not null
#  paid_up_ymd          :string(8)
#  status               :integer          default("not_opened_yet"), not null
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

class ProjectPhase < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :project
  has_many :project_phase_evidences
  has_many :project_phase_sites
  has_many :contractors, through: :project_phase_sites
  has_many :project_receive_amount_histories, through: :project_phase_sites
  has_many :orders, through: :project_phase_sites

  enum status: { not_opened_yet: 1, opened: 2, closed: 3 }

  validates :phase_name, presence: true

  validates :phase_value, presence: true
  validate  :phase_value_validation

  validates :phase_limit, presence: true, numericality:
    { less_than_or_equal_to: :phase_value, greater_than_or_equal_to: :total_c_phase_limit }

  validate  :phase_limit_validation

  validates :start_ymd, presence: true, length: { is: 8 }
  validates :finish_ymd, presence: true, length: { is: 8 }
  validates :due_ymd, presence: true, length: { is: 8 }

  def status_label
    enum_to_label('status')
  end

  def average_progress
    site_codes = project_phase_sites.map(&:site_code)
    return 0.0 if site_codes.count == 0

    site_infos = RudyReportSaison.new(site_codes).exec

    progress_sum = site_infos.sum{|site_code, info| info['project_complete_percent'].to_f}

    (progress_sum / site_codes.count).round(2).to_f
  end

  def average_progress_from_data(progress_data)
    site_codes = project_phase_sites.map(&:site_code)
    return 0.0 if site_codes.count == 0

    progress_sum = site_codes.sum{|site_code| progress_data[site_code]}

    (progress_sum / site_codes.count).round(2).to_f
  end

  def surcharge_amount
    (repayment_amount - phase_value).round(2).to_f
  end

  def paid_repayment_amount
    # 分母を超えないように調整
    [paid_total_amount_with_refund, repayment_amount].min
  end

  def repayment_amount
    # オーダーの支払い予定額(利息・遅損金を含む)
    calc_total_amount = project_phase_sites.sum{|site|
      site.payment_list_orders.sum(&:calc_total_amount)
    }.round(2)

    [calc_total_amount, phase_value].max.to_f
  end

  def paid_total_amount
    project_phase_sites.sum(&:paid_total_amount).round(2).to_f
  end

  def paid_total_amount_with_refund
    project_phase_sites.sum(&:paid_total_amount_with_refund).round(2)
  end

  def total_c_phase_limit
    project_phase_sites.sum(:phase_limit)
  end

  def phase_value_validation
    # 自身を除いだPhase Valueの合計
    total_phase_value_without_self =
      project.project_phases.sum(:phase_value) - phase_value_was.to_f

    # 新しいPhaseValueの合計
    new_total_phase_value = total_phase_value_without_self + phase_value.to_f

    # PhaseValueの合計がProjectValueを超えていればエラー
    if project.project_value < new_total_phase_value
      errors.add(
        :phase_value,
        :less_than_or_equal_to,
        count: project.project_value - total_phase_value_without_self # 登録可能な額
      )
    end
  end

  def phase_limit_validation
    # 自身を除いだPhase Limitの合計
    total_phase_limit_without_self =
      project.project_phases.sum(:phase_limit) - phase_limit_was.to_f

    # 新しいPhaseLimitの合計
    new_total_phase_limit = total_phase_limit_without_self + phase_limit.to_f

    # PhaseLimitの合計がProjectLimitを超えていればエラー
    if project.project_limit < new_total_phase_limit
      errors.add(
        :phase_limit,
        :less_than_or_equal_to,
        count: project.project_limit - total_phase_limit_without_self # 登録可能な額
      )
    end
  end
end
