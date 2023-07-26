# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AwsSns, type: :model do
  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day)
  end

  describe '#format_mobile_number' do
    it '先頭の数字が消えないこと' do
      mobile_number = AwsSns.send(:format_mobile_number, '1234567890')
      expect(mobile_number).to eq '+811234567890'
    end

    it '先頭の0が消えること' do
      mobile_number = AwsSns.send(:format_mobile_number, '0123456789')
      expect(mobile_number).to eq '+81123456789'
    end
  end
end
