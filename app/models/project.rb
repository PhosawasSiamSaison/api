# == Schema Information
#
# Table name: projects
#
#  id                      :bigint(8)        not null, primary key
#  project_code            :string(255)      not null
#  project_type            :integer          not null
#  project_name            :string(255)      not null
#  project_manager_id      :bigint(8)        not null
#  project_value           :decimal(10, 2)
#  project_limit           :decimal(10, 2)   not null
#  delay_penalty_rate      :integer          not null
#  project_owner           :string(40)
#  start_ymd               :string(8)        not null
#  finish_ymd              :string(8)        not null
#  address                 :string(1000)
#  progress                :integer          default(0), not null
#  status                  :integer          default("opened"), not null
#  contract_registered_ymd :string(8)        not null
#  create_user_id          :bigint(8)        not null
#  update_user_id          :bigint(8)        not null
#  deleted                 :integer          default(0)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  operation_updated_at    :datetime
#  lock_version            :integer          default(0), not null
#

class Project < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :project_manager
  belongs_to :create_user, class_name: :JvUser, unscoped: true
  belongs_to :update_user, class_name: :JvUser, unscoped: true
  has_many :project_phases
  has_many :project_phase_sites, through: :project_phases
  has_many :orders, through: :project_phase_sites
  has_many :installments, through: :orders

  has_many :contractors, through: :project_phases
  has_many :project_documents

  enum project_type: {
    detached_house: 1,
    renovation_work: 2
  }
  enum status: { opened: 1, closed: 2 }

  validates :project_code, presence: true
  validates :project_type, presence: true
  validates :project_name, presence: true

  validates :project_value, presence: true, numericality:
    { greater_than_or_equal_to: :total_phase_value }

  validates :project_limit, presence: true, numericality:
    { less_than_or_equal_to: :project_value, greater_than_or_equal_to: :total_phase_limit }

  validates :start_ymd, presence: true, length: { is: 8 }
  validates :finish_ymd, presence: true, length: { is: 8 }
  validates :contract_registered_ymd, presence: true, length: { is: 8 }

  validates :delay_penalty_rate, presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  class << self
    def search(params)
      relation = all.includes(:contractors)

      if params.dig(:search, :project_code).present?
        project_code = params.dig(:search, :project_code)
        relation = relation.where(project_code: project_code)
      end

      if params.dig(:search, :project_manager_id).present?
        project_manager_id = params.dig(:search, :project_manager_id)

        relation = relation.joins(:project_manager)
          .where(project_manager_id: project_manager_id)
      end

      if params.dig(:search, :start_date).present?
        start_date = params.dig(:search, :start_date)
        from_ymd = start_date[:from_ymd].presence || "00000000"
        to_ymd   = start_date[:to_ymd].presence || "99999999"

        relation = relation.where(start_ymd: from_ymd..to_ymd)
      end

      if params.dig(:search, :site_name).present?
        site_name = params.dig(:search, :site_name)

        relation = relation.eager_load(:project_phase_sites)
          .where('project_phase_sites.site_name LIKE ?', "%#{site_name}%")
      end

      if params.dig(:search, :site_code).present?
        site_code = params.dig(:search, :site_code)

        relation = relation.eager_load(:project_phase_sites)
          .where('project_phase_sites.site_code LIKE ?', "%#{site_code}%")
      end

      if params.dig(:search, :tax_id).present?
        tax_id = params.dig(:search, :tax_id)

        relation = relation.where(contractors: { tax_id: tax_id })
      end

      if params.dig(:search, :contractor_name).present?
        contractor_name = params.dig(:search, :contractor_name)

        relation = relation.joins(:contractors).where(
          'CONCAT(contractors.th_company_name, contractors.en_company_name) LIKE ?',
          "%#{contractor_name}%"
        )
      end

      if params.dig(:search, :include_closed_project) == true
        relation = relation.where(status: :opened).or(relation.where(status: :closed))
      end

      if params.dig(:search, :include_closed_project) == false
        relation = relation.where(status: :opened)
      end

      if params[:page].present? && params[:per_page].present?
        result = paginate(params[:page], relation, params[:per_page])
      else
        result = relation
      end

      [result, relation.count]
    end

    def search_for_project_manager(params, login_user)
      relation = login_user.project_manager.projects.all.includes(:project_manager, :contractors)

      if params.dig(:search, :project_code).present?
        project_code = params.dig(:search, :project_code)
        relation = relation.where(project_code: project_code)
      end

      if params.dig(:search, :start_date).present?
        start_date = params.dig(:search, :start_date)
        from_ymd = start_date[:from_ymd].presence || "00000000"
        to_ymd   = start_date[:to_ymd].presence || "99999999"

        relation = relation.where(start_ymd: from_ymd..to_ymd)
      end

      # tax_idによる絞り込み
      if params.dig(:search, :tax_id).present?
        tax_id = params.dig(:search, :tax_id)
        relation = relation.where(contractors: { tax_id: tax_id })
      end

      # contractor Name(Company Name)による絞り込み
      if params.dig(:search, :contractor_name).present?
        contractor_name = params.dig(:search, :contractor_name)
        relation = relation.joins(:contractors).where(
          'CONCAT(contractors.th_company_name, contractors.en_company_name) LIKE ?',
          "%#{contractor_name}%"
        )
      end

      if params.dig(:search, :include_closed_project) == true
        relation = relation.where(status: :opened).or(relation.where(status: :closed))
      end

      if params.dig(:search, :include_closed_project) == false
        relation = relation.where(status: :opened)
      end

      if params[:page].present? && params[:per_page].present?
        result = paginate(params[:page], relation, params[:per_page])
      else
        result = relation
      end

      [result, relation.count]
    end

    def search_for_contractor(params, login_user)
      relation = login_user.contractor.projects

      if params.dig(:project_code).present?
        project_code = params.dig(:project_code)
        relation = relation.where("project_code LIKE ?", "#{project_code}%")
      end

      if params.dig(:show_all_projects) == 'false'
        relation = relation.opened
      end

      relation.distinct
    end
  end

  def total_purchase_amount
    project_phase_sites.sum{|project_phase_site|
      project_phase_site.total_principal
    }
  end

  def total_phase_value
    project_phases.sum(:phase_value).to_f
  end

  def total_phase_limit
    project_phases.sum(:phase_limit).to_f
  end

  def paid_total_amount_with_refund
    project_phases.sum(&:paid_total_amount_with_refund).round(2)
  end

  def project_type_label
    enum_to_label('project_type')
  end

  def status_label
    enum_to_label('status')
  end
end
