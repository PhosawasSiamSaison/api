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

require 'rails_helper'

RSpec.describe DealerTypeSetting, type: :model do
  let(:dealer_user) { FactoryBot.create(:dealer_user) }

  describe 'レコード有無の確認' do
    it '本番にデータを追加する(もしくは報告をする)' do
      ApplicationRecord.dealer_types.keys.map do |dealer_type|
        dealer_type_setting = DealerTypeSetting.find_by(dealer_type: dealer_type)
        expect(dealer_type_setting.present?).to eq true
      end
    end
  end
end
