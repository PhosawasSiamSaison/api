# frozen_string_literal: true

# == Schema Information
#
# Table name: contractor_billing_zip_ymds
#
#  id                   :bigint(8)        not null, primary key
#  due_ymd              :string(8)        not null
#  created_at           :datetime
#  updated_at           :datetime
#  operation_updated_at :datetime
#


class ContractorBillingZipYmd < ApplicationRecord
  has_one_attached :zip_file

  validates :due_ymd, uniqueness: { case_sensitive: false }
end
