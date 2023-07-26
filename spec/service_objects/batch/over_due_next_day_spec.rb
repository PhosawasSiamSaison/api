# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Batch::OverDueNextDay do
  describe 'exec' do
    before do
      FactoryBot.create(:system_setting)
    end

    context 'business_ymd: 20190116' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190116')
      end

      context 'status: over_due, due_ymd: 20190115' do
        let(:contractor) { FactoryBot.create(:contractor_user).contractor }

        before do
          order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190115')
          payment = FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20190115')
          FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190115', principal: 1000000.0)
        end

        it 'SMSが送信されること' do
          Batch::OverDueNextDay.exec

          expect(SmsSpool.count).to eq 1
          sms = SmsSpool.first
          expect(sms.message_type).to eq 'over_due_next_day'
        end

        it 'SMS内容が正しいこと' do
          Batch::OverDueNextDay.exec

          expect(SmsSpool.count).to eq 1
          sms = SmsSpool.first
          expect(sms.message_body.include?('1,000,986.3')).to eq true
          # expect(sms.message_body.include?('ท่านมียอดครบกำหนดชำระ')).to eq true
          # expect(sms.message_body.include?('สำหรับรายละเอียดเพิ่มเติม')).to eq true
          # expect(sms.message_body.include?('ขออภัยหากท่านชำระแล้ว')).to eq true
        end

        context '請求系のSMSを止める' do
          before do
            contractor.update!(stop_payment_sms: true)
          end

          it 'SMSが送信されないこと' do
            Batch::OverDueNextDay.exec

            expect(SmsSpool.count).to eq 0
          end
        end
      end

      context 'status: paid, due_ymd: 2010115 (異なるステータス)' do
        before do
          contractor_user = FactoryBot.create(:contractor_user)
          FactoryBot.create(:payment, :paid, contractor: contractor_user.contractor, due_ymd: '20190115')
        end

        it 'SMSが送信され ない こと' do
          Batch::OverDueNextDay.exec

          expect(SmsSpool.count).to eq 0
        end
      end

      context '対象外のUserType' do
        before do
          contractor_user = FactoryBot.create(:contractor_user, user_type: 'other')
          FactoryBot.create(:payment, :over_due, contractor: contractor_user.contractor, due_ymd: '20190115')
        end

        it 'SMSが送信されない' do
          Batch::OverDueNextDay.exec

          expect(SmsSpool.count).to eq 0
        end
      end
    end

    context 'business_ymd: 20190301' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190301')
      end

      context 'status: over_due, due_ymd: 20190228' do
        let(:contractor) { FactoryBot.create(:contractor_user).contractor }

        before do
          order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190116')
          payment = FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20190228')
          FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190228', principal: 1000.0)
        end

        it 'SMSが送信されること' do
          Batch::OverDueNextDay.exec

          expect(SmsSpool.count).to eq 1
          sms = SmsSpool.first
          expect(sms.message_type).to eq 'over_due_next_day'
        end

        context 'エビデンスチェック待ち' do
          before do
            contractor.update!(check_payment: true)
          end

          it 'SMSが送信されるないこと' do
            Batch::OverDueNextDay.exec

            expect(SmsSpool.count).to eq 0
          end
        end
      end
    end

    # 実行対象外の日付
    context 'business_ymd: 20190117' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190117')
      end

      context 'status: over_due, due_ymd: 20190115' do
        before do
          contractor_user = FactoryBot.create(:contractor_user)
          FactoryBot.create(:payment, :over_due, contractor: contractor_user.contractor, due_ymd: '20190115')
        end

        it 'SMSが送信される ない こと' do
          Batch::OverDueNextDay.exec

          expect(SmsSpool.count).to eq 0
        end
      end
    end

    # １ヶ月後にも送られること
    context 'business_ymd: 20190216' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190216')
      end

      context 'status: over_due, due_ymd: 20190115' do
        let(:contractor) { FactoryBot.create(:contractor_user).contractor }

        before do
          order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190115')
          payment = FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20190115')
          FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190115', principal: 1000000.0)
        end

        it 'SMSが送信されること' do
          Batch::OverDueNextDay.exec

          expect(SmsSpool.count).to eq 1
          sms = SmsSpool.first
          expect(sms.message_type).to eq 'over_due_next_day'
        end
      end
    end

    # １ヶ月後にも送られること
    context '締め日が同じ(月が異なる)遅延Paymentが2件' do
      let(:contractor) { FactoryBot.create(:contractor_user).contractor }

      before do
        FactoryBot.create(:business_day, business_ymd: '20190316')
      end

      before do
        order1 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190115')
        order2 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190215')

        payment1 = FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20190115')
        payment2 = FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20190215')

        FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190115',
          principal: 1000.0)

        FactoryBot.create(:installment, order: order2, payment: payment2, due_ymd: '20190215',
          principal: 1000.0)
      end

      it 'SMSが1通のみ送信されること' do
        Batch::OverDueNextDay.exec

        expect(SmsSpool.count).to eq 1
        sms = SmsSpool.first
        expect(sms.message_type).to eq 'over_due_next_day'
      end
    end
  end
end
