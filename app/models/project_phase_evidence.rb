# == Schema Information
#
# Table name: project_phase_evidences
#
#  id                   :bigint(8)        not null, primary key
#  project_phase_id     :bigint(8)        not null
#  evidence_number      :string(10)       not null
#  comment              :text(65535)
#  checked_at           :datetime
#  checked_user_id      :bigint(8)
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

class ProjectPhaseEvidence < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :project_phase
  belongs_to :checked_user, class_name: :JvUser, optional: true
  has_one_attached :file

  scope :sort_list, -> { order(created_at: :desc, id: :desc) }
  
  validates :evidence_number, presence: true, length: { is: 10 }
  validates :comment, length: { maximum: 500 }

  class << self
    def get_prev_id(evidence)
      where('created_at >= ? and id > ?', evidence.created_at, evidence.id).reverse.first&.id
    end

    def get_next_id(evidence)
      where('created_at <= ? and id < ?', evidence.created_at, evidence.id).first&.id
    end
  end
end
