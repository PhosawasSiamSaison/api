# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RescheduleOrderInterestList, type: :model do
  describe 'get_interest' do
    it '値が取得できること' do
      interest = RescheduleOrderInterestList.new.get_interest(1)

      expect(interest.is_a?(Integer) || interest.is_a?(Float)).to eq true
    end
  end

  describe 'list' do
    it 'キーが1~60であること' do
      list = RescheduleOrderInterestList.new.list

      expect(list.keys == (1..60).to_a).to eq true
    end
  end
end
