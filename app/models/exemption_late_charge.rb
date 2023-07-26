# == Schema Information
#
# Table name: exemption_late_charges
#
#  id                   :bigint(8)        not null, primary key
#  installment_id       :bigint(8)
#  amount               :decimal(10, 2)   default(0.0), not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class ExemptionLateCharge < ApplicationRecord
  belongs_to :installment
end
