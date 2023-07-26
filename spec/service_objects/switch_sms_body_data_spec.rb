# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SwitchMessageBodyData, type: :model do
  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20210408')
  end

  describe '#switch_message_body_data' do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:payment) { FactoryBot.create(:payment) }

    context '通常パターン' do
      let(:payment) { FactoryBot.create(:payment, :next_due, due_ymd: '20210415') }
      let(:order1) { FactoryBot.create(:order, :cbm,   :inputed_date, contractor: contractor, purchase_amount: 100) }
      let(:order2) { FactoryBot.create(:order, :cbm,   :inputed_date, contractor: contractor, purchase_amount: 200) }
      let(:order3) { FactoryBot.create(:order, :cpac,  :inputed_date, contractor: contractor, purchase_amount: 400) }
      let(:order4) { FactoryBot.create(:order, :q_mix, :inputed_date, contractor: contractor, purchase_amount: 800) }

      before do
        FactoryBot.create(:installment, payment: payment, order: order1)
        FactoryBot.create(:installment, payment: payment, order: order2)
        FactoryBot.create(:installment, payment: payment, order: order3)
        FactoryBot.create(:installment, payment: payment, order: order4)
      end

      it 'データが正しく取得できること' do
        switch_message_body_data = SwitchMessageBodyData.new.call(payment)

        cbm_data   = switch_message_body_data.find{|data| data[:dealer_type] == 'cbm'}
        cpac_data  = switch_message_body_data.find{|data| data[:dealer_type] == 'cpac'}
        q_mix_data = switch_message_body_data.find{|data| data[:dealer_type] == 'q_mix'}

        # cbm
        expect(cbm_data[:total_due_amount]).to eq 300
        expect(cbm_data[:line_account]).to eq find_sms_line_account(:cbm)
        expect(cbm_data[:switch_sms_product_names]).to eq [
          Product.find_by(product_key: 1).switch_sms_product_name,
          Product.find_by(product_key: 2).switch_sms_product_name,
          Product.find_by(product_key: 3).switch_sms_product_name,
          Product.find_by(product_key: 4).switch_sms_product_name,
          Product.find_by(product_key: 5).switch_sms_product_name,
          Product.find_by(product_key: 8).switch_sms_product_name,
        ]
        # cpac
        expect(cpac_data[:total_due_amount]).to eq 400
        expect(cpac_data[:line_account]).to eq find_sms_line_account(:cpac)
        expect(cpac_data[:switch_sms_product_names]).to eq [
          Product.find_by(product_key: 1).switch_sms_product_name,
          Product.find_by(product_key: 2).switch_sms_product_name,
          Product.find_by(product_key: 3).switch_sms_product_name,
          Product.find_by(product_key: 4).switch_sms_product_name,
          Product.find_by(product_key: 5).switch_sms_product_name,
          Product.find_by(product_key: 8).switch_sms_product_name,
        ]
        # q_mix
        expect(q_mix_data[:line_account]).to eq find_sms_line_account(:q_mix)
      end

      context 'sub_dealer' do
        before do
          contractor.sub_dealer!
        end

        it 'line_accountがsub_dealer用になること' do
          switch_message_body_data = SwitchMessageBodyData.new.call(payment)

          cbm_data  = switch_message_body_data.find{|data| data[:dealer_type] == 'cbm'}
          cpac_data = switch_message_body_data.find{|data| data[:dealer_type] == 'cpac'}

          expect(cbm_data[:line_account]).to eq SmsSpool::SUB_DEALER_LINE_ACCOUNT
          expect(cpac_data[:line_account]).to eq SmsSpool::SUB_DEALER_LINE_ACCOUNT
        end
      end
    end
  end

  private
  def find_sms_line_account(dealer_type)
    Dealer.find_by(dealer_type: dealer_type).dealer_type_setting.sms_line_account
  end
end
