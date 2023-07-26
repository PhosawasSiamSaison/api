# frozen_string_literal: true

# == Schema Information
#
# Table name: contractor_user_pdpa_versions
#
#  id                   :bigint(8)        not null, primary key
#  contractor_user_id   :bigint(8)        not null
#  pdpa_version_id      :bigint(8)        not null
#  agreed               :boolean          default(TRUE), not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime
#  updated_at           :datetime
#  operation_updated_at :datetime
#


class ContractorUserPdpaVersion < ApplicationRecord
  belongs_to :contractor_user
  belongs_to :pdpa_version

  scope :agreed, -> { where(agreed: true) }

  class << self
    def latest_agreed_at
      find_by(pdpa_version: PdpaVersion.latest)&.created_at
    end
  end
end
