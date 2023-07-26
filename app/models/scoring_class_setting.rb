# == Schema Information
#
# Table name: scoring_class_settings
#
#  id                   :bigint(8)        not null, primary key
#  class_a_min          :integer          not null
#  class_b_min          :integer          not null
#  class_c_min          :integer          not null
#  class_a_limit_amount :decimal(10, 2)   not null
#  class_b_limit_amount :decimal(10, 2)   not null
#  class_c_limit_amount :decimal(10, 2)   not null
#  latest               :boolean          default(FALSE), not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  lock_version         :integer          default(0)
#

class ScoringClassSetting < ApplicationRecord
  validates :class_a_min,
            :class_b_min,
            :class_c_min,
            :class_a_limit_amount,
            :class_b_limit_amount,
            :class_c_limit_amount,
            :latest,
            presence: true

  class << self
    def latest
      find_by(latest: true)
    end

    def update(params)
      ActiveRecord::Base.transaction do
        latest&.update!(latest: false)

        create!(params.merge(latest: true))
      end
    end
  end
end
