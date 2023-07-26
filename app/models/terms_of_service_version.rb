# frozen_string_literal: true
# == Schema Information
#
# Table name: terms_of_service_versions
#
#  id                   :bigint(8)        not null, primary key
#  contractor_user_id   :bigint(8)
#  dealer_type          :integer
#  sub_dealer           :boolean          default(FALSE), not null
#  integrated           :boolean          default(FALSE), not null
#  individual           :boolean          default(FALSE), not null
#  version              :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class TermsOfServiceVersion < ApplicationRecord
  belongs_to :contractor_user

  # 規約タイプの定数
  INTEGRATED = :integrated
  SUB_DEALER = :sub_dealer
  INDIVIDUAL = :individual

  class << self
    # 規約タイプからレコードを探す
    def find_by_type(terms_of_service_type)
      if terms_of_service_type == INTEGRATED
        find_by(integrated: true)
      elsif terms_of_service_type == SUB_DEALER
        find_by(sub_dealer: true)
      elsif terms_of_service_type == INDIVIDUAL
        find_by(individual: true)
      else
        find_by(dealer_type: terms_of_service_type)
      end
    end
  end
end
