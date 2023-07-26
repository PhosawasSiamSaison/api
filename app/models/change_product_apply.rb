# == Schema Information
#
# Table name: change_product_applies
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)
#  due_ymd              :string(8)        not null
#  completed_at         :datetime
#  memo                 :string(500)
#  apply_user_id        :integer
#  register_user_id     :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class ChangeProductApply < ApplicationRecord
  has_many :orders
  belongs_to :contractor
  belongs_to :apply_user, class_name: 'ContractorUser', optional: true, unscoped: true
  belongs_to :register_user, class_name: 'JvUser', optional: true, unscoped: true

  scope :not_completed, -> { where(completed_at: nil) }

  class << self
    def search_list(params)
      relation = eager_load(:contractor)
                  .order(due_ymd: :ASC, created_at: :ASC, id: :ASC)

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

      # Include Completed Application
      if params.dig(:search, :include_completed).to_s != 'true'
        relation = relation.not_completed
      end

      result = paginate(params[:page], relation, params[:per_page])
      [result, relation.count]
    end
  end

  def can_register?
    completed_at.nil?
  end
end
