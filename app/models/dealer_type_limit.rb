# frozen_string_literal: true
# == Schema Information
#
# Table name: dealer_type_limits
#
#  id                   :bigint(8)        not null, primary key
#  eligibility_id       :bigint(8)
#  dealer_type          :integer          default("cbm"), not null
#  limit_amount         :decimal(13, 2)   not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class DealerTypeLimit < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :eligibility

  def dealer_type_label
    # application_record に定義した localeを使用する
    enum_to_label('dealer_type', class_name: 'application_record')
  end
end
