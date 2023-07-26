# frozen_string_literal: true
# == Schema Information
#
# Table name: system_settings
#
#  id                                    :bigint(8)        not null, primary key
#  front_jv_version                      :string(255)
#  front_c_version                       :string(255)
#  front_d_version                       :string(255)
#  front_pm_version                      :string(255)
#  verify_mode                           :integer          default("one_time_passcode"), not null
#  sms_provider                          :integer          default("aws_sns"), not null
#  is_downloading_csv                    :boolean          default(FALSE), not null
#  integrated_terms_of_service_version   :integer          default(1), not null
#  cbm_terms_of_service_version          :integer          default(0), not null
#  cpac_terms_of_service_version         :integer          default(0), not null
#  global_house_terms_of_service_version :integer          default(1), not null
#  transformer_terms_of_service_version  :integer          default(1), not null
#  solution_terms_of_service_version     :integer          default(1), not null
#  b2b_terms_of_service_version          :integer          default(1), not null
#  q_mix_terms_of_service_version        :integer          default(1), not null
#  nam_terms_of_service_version          :integer          default(1), not null
#  bigth_terms_of_service_version        :integer          default(1), not null
#  permsin_terms_of_service_version      :integer          default(1), not null
#  scgp_terms_of_service_version         :integer          default(1), not null
#  rakmao_terms_of_service_version       :integer          default(1), not null
#  cotto_terms_of_service_version        :integer          default(1), not null
#  d_gov_terms_of_service_version        :integer          default(1), not null
#  sub_dealer_terms_of_service_version   :integer          default(1), not null
#  individual_terms_of_service_version   :integer          default(1), not null
#  credit_limit_additional_rate          :decimal(5, 2)
#  order_one_time_passcode_limit         :integer          default(15)
#  deleted                               :integer          default(0), not null
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#  operation_updated_at                  :datetime
#  lock_version                          :integer          default(0)
#

class SystemSetting < ApplicationRecord
  default_scope { where(deleted: 0) }

  # 中間の締め日の定数
  CLOSING_DAY = 15

  enum verify_mode: { one_time_passcode: 1, login_passcode: 2 }
  enum sms_provider: { thai_bulk_sms: 1, aws_sns: 2 }

  def closing_day
    CLOSING_DAY
  end

  def get_terms_of_service_version(terms_of_service_type)
    # terms_of_service_typeに合ったカラムの値を取得する
    send("#{terms_of_service_type.to_s}_terms_of_service_version")
  end

  private
  # クラメソッドが呼ばれた場合に、同名のインスタンスメソッドを呼ぶ
  def self.method_missing(method, *args)
    first.send(method, *args)
  end
end
