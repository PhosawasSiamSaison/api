# frozen_string_literal: true
# == Schema Information
#
# Table name: rudy_api_settings
#
#  id                   :bigint(8)        not null, primary key
#  user_name            :string(255)
#  password             :string(255)
#  bearer               :string(255)
#  response_header_text :text(65535)
#  response_text        :text(65535)
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class RudyApiSetting < ApplicationRecord
  default_scope { where(deleted: 0) }

  private
  # クラメソッドが呼ばれた場合に、同名のインスタンスメソッドを呼ぶ
  def self.method_missing(method, *args)
    first.send(method, *args)
  end
end
