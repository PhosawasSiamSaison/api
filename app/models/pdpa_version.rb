# frozen_string_literal: true

# == Schema Information
#
# Table name: pdpa_versions
#
#  id                   :bigint(8)        not null, primary key
#  version              :integer          default(1), not null
#  file_url             :string(255)      not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime
#  updated_at           :datetime
#  operation_updated_at :datetime
#


class PdpaVersion < ApplicationRecord
  has_one :contractor_user_pdpa_version

  class << self
    def latest
      order(:version).last
    end

    def latest?
      latest == unscoped.all.latest
    end
  end

  def latest?
    version == PdpaVersion.latest.version
  end
end
