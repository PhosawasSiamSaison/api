# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Batch::SendCanSwitch7daysAgoSms do
  let(:contractor_user) { FactoryBot.create(:contractor_user) }
  let(:contractor) { contractor_user.contractor }
  let(:order) { Order.first }
  let(:payment) { Payment.first }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day)

    FactoryBot.create(:order, contractor: contractor, input_ymd: input_ymd)
    FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: due_ymd)
    FactoryBot.create(:installment, order: order, payment: payment, due_ymd: due_ymd,
      principal: 1000000.0)
  end

  describe '実行日' do
    before do
      BusinessDay.update!(business_ymd: exec_ymd)
    end

    context '１５日の１週間前：20190208' do
      let(:exec_ymd)  { '20190208' }
      let(:input_ymd) { '20190115' }
      let(:due_ymd)   { '20190215' }

      it 'SMSが送信されること' do
        Batch::SendCanSwitch7daysAgoSms.exec

        expect(SmsSpool.count).to eq 1
        sms = SmsSpool.first
        expect(sms.message_type).to eq 'can_switch_7days_ago_sms'
      end

      context 'stop_payment_sms: true' do
        before do
          contractor.update!(stop_payment_sms: true)
        end

        it 'SMSが送信されないこと' do
          Batch::SendCanSwitch7daysAgoSms.exec

          expect(SmsSpool.count).to eq 0
        end
      end

      context '変更できる商品がない' do
        before do
          Product.all.each do |product|
            FactoryBot.create(:available_product, :switch, contractor: contractor, product: product,
              available: false)
          end
        end

        it 'SMSが送信されないこと' do
          Batch::SendCanSwitch7daysAgoSms.exec

          expect(SmsSpool.count).to eq 0
        end
      end
    end

    context '月末の１週間前：20190221' do
      let(:exec_ymd)  { '20190221' }
      let(:input_ymd) { '20190116' }
      let(:due_ymd)   { '20190228' }

      it 'SMSが送信されること' do
        Batch::SendCanSwitch7daysAgoSms.exec

        expect(SmsSpool.count).to eq 1
        sms = SmsSpool.first
        expect(sms.message_type).to eq 'can_switch_7days_ago_sms'
      end
    end
  end

  describe '実行日以外' do
    before do
      BusinessDay.update!(business_ymd: exec_ymd)
    end

    context '適当な日付：20190207' do
      let(:exec_ymd)  { '20190207' }
      let(:input_ymd) { '20190115' }
      let(:due_ymd)   { '20190215' }

      it 'SMSが送信されないこと' do
        Batch::SendCanSwitch7daysAgoSms.exec

        expect(SmsSpool.count).to eq 0
      end
    end
  end
end
