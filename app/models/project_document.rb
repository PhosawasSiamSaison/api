# == Schema Information
#
# Table name: project_documents
#
#  id                   :bigint(8)        not null, primary key
#  project_id           :bigint(8)        not null
#  file_type            :integer          not null
#  ss_staff_only        :boolean          default(FALSE)
#  file_name            :string(100)      not null
#  comment              :text(65535)
#  create_user_id       :bigint(8)        not null
#  update_user_id       :bigint(8)        not null
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

class ProjectDocument < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :project
  belongs_to :create_user, class_name: :JvUser, unscoped: true
  belongs_to :update_user, class_name: :JvUser, unscoped: true
  has_one_attached :file

  enum file_type: {
    right_transfer_agreement: 1,
    acceptance_agreement: 2,
    phase_delivery_letter: 3,
    phase_acceptance_agreement: 4,
    mou: 5,
    etc: 6,
    contract: 7
  }

  validates :file_type, presence: true
  validates :file_name, presence: true, length: { maximum: 100 }
  validates :comment, length: { maximum: 500 }

  class << self
    def get_not_ss_staff_only
      all.where(ss_staff_only: false)
    end
  end

  def file_type_label
    enum_to_label('file_type')
  end
end
