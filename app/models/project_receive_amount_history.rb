# frozen_string_literal: true

# == Schema Information
#
# Table name: project_receive_amount_histories
#
#  id                    :bigint(8)        not null, primary key
#  contractor_id         :bigint(8)        not null
#  project_phase_site_id :bigint(8)        not null
#  receive_ymd           :string(8)        not null
#  receive_amount        :decimal(10, 2)   not null
#  exemption_late_charge :decimal(10, 2)
#  comment               :text(65535)
#  create_user_id        :bigint(8)        not null
#  deleted               :integer          default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  operation_updated_at  :datetime
#  lock_version          :integer          default(0)
#


class ProjectReceiveAmountHistory < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :contractor
  belongs_to :project_phase_site
  belongs_to :create_user, class_name: :JvUser, unscoped: true
end
