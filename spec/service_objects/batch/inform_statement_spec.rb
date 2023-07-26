# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Batch::InformStatement do
  describe 'exec' do
    let(:contractor_user) { FactoryBot.create(:contractor_user) }
    let(:contractor) { contractor_user.contractor }

    before do
      FactoryBot.create(:system_setting)
    end

    context 'business_ymd: 20190116' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190116')
      end

      context 'status: next_due, due_ymd: 20190215' do
        before do
          order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190115')
          payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')
          FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190215', principal: 1000000.0)
        end

        it 'SMSが送信されること' do
          Batch::InformStatement.exec

          expect(SmsSpool.count).to eq 1
          sms = SmsSpool.first
          expect(sms.message_type).to eq 'inform_statement'
        end

        it 'SMS内容が正しいこと' do
          Batch::InformStatement.exec

          expect(SmsSpool.count).to eq 1
          sms = SmsSpool.first
          expect(sms.message_body.include?('1,000,000.0')).to eq true
          expect(sms.message_body.include?('15 / 02 / 2019')).to eq true
          # expect(sms.message_body.include?('ท่านมียอดที่ต้องชำระ')).to eq true
          # expect(sms.message_body.include?('บาท จะครบกำหนดในวันที่')).to eq true
          # expect(sms.message_body.include?('สำหรับรายละเอียดเพิ่มเติม กรุณากด')).to eq true
        end

        describe '請求系SMSを送らない' do
          before do
            contractor.update!(stop_payment_sms: true)
          end

          it 'SMSが送信されないこと' do
            Batch::InformStatement.exec

            expect(SmsSpool.count).to eq 0
          end
        end
      end

      context 'status: paid, due_ymd: 20190215' do
        before do
          payment = FactoryBot.create(:payment, :paid, contractor: contractor, due_ymd: '20190215')
          order = FactoryBot.create(:order, :inputed_date)
          FactoryBot.create(:installment, order: order, payment: payment)
        end

        it 'SMSが送信されること' do
          Batch::InformStatement.exec

          expect(SmsSpool.count).to eq 1
          sms = SmsSpool.first
          expect(sms.message_type).to eq 'inform_statement'
        end
      end

      context 'status: next_due, due_ymd: 20190228' do
        before do
          FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190228')
        end

        it 'SMSが送信される ない こと' do
          Batch::InformStatement.exec

          expect(SmsSpool.count).to eq 0
        end
      end

      context '対象外のUserType' do
        before do
          contractor_user.update!(user_type: 'other')
          FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')
        end

        it 'SMSが送信されないこと' do
          Batch::InformStatement.exec

          expect(SmsSpool.count).to eq 0
        end
      end
    end

    # 実行対象外の日付
    context 'business_ymd: 20190117' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190117')
      end

      context 'status: next_due, due_ymd: 20190215' do
        before do
          FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')
        end

        it 'SMSが送信される ない こと' do
          Batch::InformStatement.exec

          expect(SmsSpool.count).to eq 0
        end
      end
    end
  end

  describe 'next_due_ymd' do
    before do
      FactoryBot.create(:system_setting)
    end

    describe '締め日が月末' do
      before do
        # 翌日を設定
        FactoryBot.create(:business_day, business_ymd: '20190101')
      end

      it '月末が取得されること' do
        next_due_ymd = Batch::InformStatement.send(:next_due_ymd)
        expect(next_due_ymd).to eq '20190131'
      end
    end

    describe '締め日が15日' do
      before do
        # 翌日を設定
        FactoryBot.create(:business_day, business_ymd: '20190116')
      end

      it '翌月の15日が取得されること' do
        next_due_ymd = Batch::InformStatement.send(:next_due_ymd)
        expect(next_due_ymd).to eq '20190215'
      end
    end
  end
end
