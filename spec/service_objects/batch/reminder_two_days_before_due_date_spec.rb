# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Batch::ReminderTwoDaysBeforeDueDate do
  describe 'exec' do
    before do
      FactoryBot.create(:system_setting)
    end

    context 'business_ymd: 20190113' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190113')
      end

      context 'status: next_due, due_ymd: 20190115' do
        let(:contractor) { FactoryBot.create(:contractor_user).contractor }

        before do
          order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20181215')
          payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190115')
          FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190115', principal: 1000000.0)
        end

        it 'SMSが送信されること' do
          Batch::ReminderTwoDaysBeforeDueDate.exec

          expect(SmsSpool.count).to eq 1
          sms = SmsSpool.first
          expect(sms.message_type).to eq 'reminder_two_days_before_due_date'
        end

        it 'SMS内容が正しいこと' do
          Batch::ReminderTwoDaysBeforeDueDate.exec

          expect(SmsSpool.count).to eq 1
          sms = SmsSpool.first
          expect(sms.message_body.include?('1,000,000.0')).to eq true
          expect(sms.message_body.include?('15 / 01 / 2019')).to eq true
          # expect(sms.message_body.include?('ท่านมียอดที่ต้องชำระ')).to eq true
          # expect(sms.message_body.include?('บาท จะครบกำหนดในวันที่')).to eq true
          # expect(sms.message_body.include?('สำหรับรายละเอียดเพิ่มเติม กรุณากด')).to eq true
          # expect(sms.message_body.include?('ขออภัยหากท่านชำระแล้ว')).to eq true
        end

        context '請求系のSMSを止める' do
          before do
            contractor.update!(stop_payment_sms: true)
          end

          it 'SMSが送信されないこと' do
            Batch::ReminderTwoDaysBeforeDueDate.exec

            expect(SmsSpool.count).to eq 0
          end
        end
      end

      context 'status: paid, due_ymd: 20190115' do
        before do
          contractor_user = FactoryBot.create(:contractor_user)
          FactoryBot.create(:payment, :paid, contractor: contractor_user.contractor, due_ymd: '20190115')
        end

        it 'SMSが送信され ない こと' do
          Batch::ReminderTwoDaysBeforeDueDate.exec

          expect(SmsSpool.count).to eq 0
        end
      end

      context 'status: next_due, due_ymd: 20190131 (異なる日付)' do
        before do
          contractor_user = FactoryBot.create(:contractor_user)
          FactoryBot.create(:payment, :next_due, contractor: contractor_user.contractor, due_ymd: '20190131')
        end

        it 'SMSが送信される ない こと' do
          Batch::ReminderTwoDaysBeforeDueDate.exec

          expect(SmsSpool.count).to eq 0
        end
      end

      context '対象外のUserType' do
        before do
          contractor_user = FactoryBot.create(:contractor_user, user_type: 'other')
          FactoryBot.create(:payment, :next_due, contractor: contractor_user.contractor, due_ymd: '20190115')
        end

        it 'SMSが送信されない' do
          Batch::ReminderTwoDaysBeforeDueDate.exec

          expect(SmsSpool.count).to eq 0
        end
      end
    end

    # 実行対象外の日付
    context 'business_ymd: 20190114' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190114')
      end

      context 'status: next_due, due_ymd: 20190115' do
        before do
          contractor_user = FactoryBot.create(:contractor_user)
          FactoryBot.create(:payment, :next_due, contractor: contractor_user.contractor, due_ymd: '20190115')
        end

        it 'SMSが送信される ない こと' do
          Batch::ReminderTwoDaysBeforeDueDate.exec

          expect(SmsSpool.count).to eq 0
        end
      end
    end
  end
end
