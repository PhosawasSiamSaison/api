# == Schema Information
#
# Table name: project_manager_users
#
#  id                   :bigint(8)        not null, primary key
#  project_manager_id   :integer          not null
#  user_type            :integer          not null
#  user_name            :string(20)
#  full_name            :string(40)       not null
#  mobile_number        :string(11)
#  email                :string(200)
#  password_digest      :string(255)      not null
#  temp_password        :string(16)
#  create_user_id       :bigint(8)        not null
#  update_user_id       :bigint(8)        not null
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

class ProjectManagerUser < ApplicationRecord
  include UserModule

  default_scope { where(deleted: 0) }
  has_secure_password

  belongs_to :project_manager
  belongs_to :create_user, class_name: :ProjectManagerUser, optional: true, unscoped: true
  belongs_to :update_user, class_name: :ProjectManagerUser, optional: true, unscoped: true

  has_many :auth_tokens, :as => :tokenable

  enum user_type: { md: 1, staff: 2 }

  validates :user_name, presence: true
  validates :user_name, length: { maximum: 20 }
  validates :user_name, uniqueness: { conditions: -> { where(deleted: 0) }}
  validates :full_name, presence: true
  validates :full_name, length: { maximum: 40 }
  validates :mobile_number, length: { maximum: 11 }
  validates :email, length: { maximum: 200 }
  validates :password, presence: true, on: :password_update
  validates :password, length: { in: 6..20 }, allow_blank: true
  validates :password, format: { with: /\A[a-z0-9A-Z]+\z/ }, allow_blank: true

  def user_type_label
    enum_to_label('user_type')
  end
  
end
