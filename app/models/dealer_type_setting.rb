# frozen_string_literal: true
# == Schema Information
#
# Table name: dealer_type_settings
#
#  id                   :bigint(8)        not null, primary key
#  dealer_type          :integer          not null
#  dealer_type_code     :string(40)       not null
#  group_type           :integer          default(NULL), not null
#  switch_auto_approval :boolean          default(TRUE), not null
#  sms_line_account     :string(255)      not null
#  sms_contact_info     :string(150)      not null
#  sms_servcie_name     :string(150)      not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class DealerTypeSetting < ApplicationRecord
  default_scope { where(deleted: 0) }

  # CreateOrderのバリデーションチェック、請求書のテンプレートの取得で使用する系統
  enum group_type: { cbm_group: 1, cpac_group: 2, project_group: 3 }
end
