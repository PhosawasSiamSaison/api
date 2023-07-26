# frozen_string_literal: true

# == Schema Information
#
# Table name: site_limit_change_applications
#
#  id                    :bigint(8)        not null, primary key
#  project_phase_site_id :bigint(8)        not null
#  site_limit            :decimal(13, 2)   not null
#  approved              :boolean          default(FALSE), not null
#  deleted               :integer          default(0)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  operation_updated_at  :datetime
#  lock_version          :integer          default(0), not null
#


class SiteLimitChangeApplication < ApplicationRecord
  belongs_to :project_phase_site
end
