# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Batch::ReminderOnDueDate do
  describe 'exec' do
    before do
      FactoryBot.create(:system_setting)
    end

    context 'business_ymd: 20190115' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190115')
      end

      context 'status: next_due, due_ymd: 20190115' do
        let(:contractor) { FactoryBot.create(:contractor_user).contractor }

        before do
          order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190115')
          payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190115')
          FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190115', principal: 1000000.0)
        end

        it 'SMSが送信されること' do
          Batch::ReminderOnDueDate.exec

          expect(SmsSpool.count).to eq 1
          sms = SmsSpool.first
          expect(sms.message_type).to eq 'reminder_on_due_date'
        end

        context '請求系のSMSを止める' do
          before do
            contractor.update!(stop_payment_sms: true)
          end

          it 'SMSが送信されないこと' do
            Batch::ReminderOnDueDate.exec

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
          Batch::ReminderOnDueDate.exec

          expect(SmsSpool.count).to eq 0
        end
      end

      context 'status: next_due, due_ymd: 20190131 (異なる日付)' do
        before do
          contractor_user = FactoryBot.create(:contractor_user)
          FactoryBot.create(:payment, :next_due, contractor: contractor_user.contractor, due_ymd: '20190131')
        end

        it 'SMSが送信される ない こと' do
          Batch::ReminderOnDueDate.exec

          expect(SmsSpool.count).to eq 0
        end
      end

      context '対象外のUserType' do
        before do
          contractor_user = FactoryBot.create(:contractor_user, user_type: 'other')
          FactoryBot.create(:payment, :next_due, contractor: contractor_user.contractor, due_ymd: '20190115')
        end

        it 'SMSが送信されない' do
          Batch::ReminderOnDueDate.exec

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
          Batch::ReminderOnDueDate.exec

          expect(SmsSpool.count).to eq 0
        end
      end
    end
  end
end
