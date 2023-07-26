# frozen_string_literal: true

# == Schema Information
#
# Table name: scoring_results
#
#  id                         :bigint(8)        not null, primary key
#  contractor_id              :bigint(8)        not null
#  scoring_class_setting_id   :bigint(8)        not null
#  limit_amount               :decimal(20, 2)   not null
#  class_type                 :integer          not null
#  financial_info_fiscal_year :integer
#  years_in_business          :integer
#  register_capital           :decimal(20, 2)
#  shareholders_equity        :decimal(20, 2)
#  total_revenue              :decimal(20, 2)
#  net_revenue                :decimal(20, 2)
#  current_ratio              :decimal(10, 2)
#  de_ratio                   :decimal(10, 2)
#  years_in_business_score    :integer
#  register_capital_score     :integer
#  shareholders_equity_score  :integer
#  total_revenue_score        :integer
#  net_revenue_score          :integer
#  current_ratio_score        :integer
#  de_ratio_score             :integer
#  total_score                :integer
#  deleted                    :integer          default(0), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  operation_updated_at       :datetime
#  lock_version               :integer          default(0)
#


class ScoringResult < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :contractor
  belongs_to :scoring_class_setting

  validates :limit_amount,
            :class_type,
            :years_in_business,
            :years_in_business_score,
            presence: true

  validates :register_capital,
            :current_ratio,
            :de_ratio,
            :register_capital_score,
            :shareholders_equity_score,
            :total_revenue_score,
            :net_revenue_score,
            :current_ratio_score,
            :de_ratio_score,
            :total_score,
            presence: true, if: :financial_info_fiscal_year_present

  def class_type_label
    enum_to_label('class_type', class_name: 'application_record')
  end

  private

  def financial_info_fiscal_year_present
    financial_info_fiscal_year.present?
  end
end
