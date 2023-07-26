# == Schema Information
#
# Table name: project_photo_comments
#
#  id                   :bigint(8)        not null, primary key
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

class ProjectPhotoComment < ApplicationRecord
  belongs_to :create_user, class_name: :JvUser, unscoped: true
  belongs_to :update_user, class_name: :JvUser, unscoped: true

  validates :file_name, presence: true, length: { maximum: 100 }
  validates :comment, presence: true, length: { maximum: 500 }
end
