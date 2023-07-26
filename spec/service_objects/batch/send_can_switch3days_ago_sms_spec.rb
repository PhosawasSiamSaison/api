# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Batch::SendCanSwitch3daysAgoSms do
  let(:contractor_user) { FactoryBot.create(:contractor_user) }
  let(:contractor) { contractor_user.contractor }
  let(:order) { Order.first }
  let(:payment) { Payment.first }
  let(:product1) { Product.find_by(product_key: 1) }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day)

    FactoryBot.create(:order, contractor: contractor, product: product1, input_ymd: input_ymd)
    FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: due_ymd)
    FactoryBot.create(:installment, order: order, payment: payment, due_ymd: due_ymd,
      principal: 1000000.0)
  end

  describe '実行日' do
    before do
      BusinessDay.update!(business_ymd: exec_ymd)
    end

    context '1/15の3営業日前：20200110' do
      let(:input_ymd) { '20191215' }
      let(:due_ymd)   { '20200115' }
      let(:exec_ymd)  { '20200110' }

      it 'SMSが送信されること' do
        Batch::SendCanSwitch3daysAgoSms.exec

        expect(SmsSpool.count).to eq 1
        sms = SmsSpool.first
        expect(sms.message_type).to eq 'can_switch_3days_ago_sms'
      end

      describe '複数のSMS' do
        let(:payment) { Payment.find_by(due_ymd: due_ymd)}

        before do
          order = FactoryBot.create(:order, :cpac, contractor: contractor, product: product1,
            input_ymd: input_ymd)
          FactoryBot.create(:installment, order: order, payment: payment, due_ymd: due_ymd,
            principal: 1000000.0)
        end

        it 'SMSが送信されること' do
          Batch::SendCanSwitch3daysAgoSms.exec

          expect(SmsSpool.count).to eq 2
          sms = SmsSpool.first
          expect(sms.message_type).to eq 'can_switch_3days_ago_sms'
        end
      end

      context 'stop_payment_sms: true' do
        before do
          contractor.update!(stop_payment_sms: true)
        end

        it 'SMSが送信されないこと' do
          Batch::SendCanSwitch3daysAgoSms.exec

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
          Batch::SendCanSwitch3daysAgoSms.exec

          expect(SmsSpool.count).to eq 0
        end
      end
    end

    context '2/29の3営業日前：20200226' do
      let(:input_ymd) { '20200116' }
      let(:due_ymd)   { '20200229' }
      let(:exec_ymd)  { '20200226' }

      it 'SMSが送信されること' do
        Batch::SendCanSwitch3daysAgoSms.exec

        expect(SmsSpool.count).to eq 1
        sms = SmsSpool.first
        expect(sms.message_type).to eq 'can_switch_3days_ago_sms'
      end
    end
  end

  describe '実行日以外' do
    before do
      BusinessDay.update!(business_ymd: exec_ymd)
    end

    context '送信される前日の日付：20200225' do
      let(:input_ymd) { '20200116' }
      let(:due_ymd)   { '20200229' }
      let(:exec_ymd)  { '20200225' }

      it 'SMSが送信されないこと' do
        Batch::SendCanSwitch3daysAgoSms.exec

        expect(SmsSpool.count).to eq 0
      end
    end
  end
end
