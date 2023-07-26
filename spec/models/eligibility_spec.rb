# frozen_string_literal: true

# == Schema Information
#
# Table name: eligibilities
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :integer          not null
#  limit_amount         :decimal(13, 2)   not null
#  class_type           :integer          not null
#  latest               :boolean          default(TRUE), not null
#  comment              :string(100)      not null
#  create_user_id       :integer
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#


require 'rails_helper'

RSpec.describe Eligibility, type: :model do
  let(:contractor) { FactoryBot.create(:contractor) }

  before do
    FactoryBot.create(:cbm_dealer)
  end

  describe 'credit_information_history_data' do
    context '範囲外のデータ' do
      before do
        FactoryBot.create(:eligibility, contractor: contractor, created_at: '2021-05-15 23:59:59')
        FactoryBot.create(:eligibility, contractor: contractor, created_at: '2021-05-17 00:00:00')
      end

      it '取得されないこと' do
        eligibilities = Eligibility.credit_information_history_data('20210516', '20210516')

        expect(eligibilities.count).to eq 0
      end

      it '指定なしで取得されること' do
        eligibilities = Eligibility.credit_information_history_data(nil, nil)

        expect(eligibilities.count).to eq 2
      end
    end

    context '範囲内のデータ' do
      before do
        FactoryBot.create(:eligibility, contractor: contractor, created_at: '2021-05-16 00:00:00')
        FactoryBot.create(:eligibility, contractor: contractor, created_at: '2021-05-16 23:59:59')
      end

      it '取得されないこと' do
        eligibilities = Eligibility.credit_information_history_data('20210516', '20210516')

        expect(eligibilities.count).to eq 2
      end
    end
  end
end
