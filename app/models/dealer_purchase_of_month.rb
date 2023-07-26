# == Schema Information
#
# Table name: dealer_purchase_of_months
#
#  id                   :bigint(8)        not null, primary key
#  dealer_id            :bigint(8)
#  month                :string(6)
#  purchase_amount      :decimal(10, 2)   default(0.0), not null
#  order_count          :integer          default(0), not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class DealerPurchaseOfMonth < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :dealer
end
