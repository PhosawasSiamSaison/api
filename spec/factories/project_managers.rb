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

FactoryBot.define do
  factory :project_manager do
    tax_id { '0000000000001' }
    project_manager_name { 'CPAC Solution' }
  end
end
