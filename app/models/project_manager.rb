# == Schema Information
#
# Table name: project_managers
#
#  id                   :bigint(8)        not null, primary key
#  tax_id               :string(13)       not null
#  shop_id              :string(10)
#  project_manager_name :string(50)       not null
#  dealer_type          :integer          default("cbm"), not null
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

class ProjectManager < ApplicationRecord
  default_scope { where(deleted: 0) }

  has_many :project_manager_users
  has_many :projects
  has_many :project_documents, through: :projects
  has_many :project_phases, through: :projects
  has_many :project_phase_evidences, through: :project_phases
  has_many :project_phase_sites, through: :project_phases
end
