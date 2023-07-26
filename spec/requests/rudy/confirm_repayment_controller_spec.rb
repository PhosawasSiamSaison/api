require 'rails_helper'

RSpec.describe Rudy::ConfirmRepaymentController, type: :request do

  describe "#call" do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:default_params) {
      {
        tax_id: contractor.tax_id,
        received_date: BusinessDay.today_ymd,
        received_amount: 100,
        repayment_id: 1,
      }
    }

    before do
      FactoryBot.create(:business_day, business_ymd: '20221003')
      FactoryBot.create(:system_setting)
      FactoryBot.create(:rudy_api_setting)
    end

    it '入金が全てExceededに入る場合に正常にメールが送られること' do
      params = default_params.dup

      post rudy_confirm_repayment_path, params: params, headers: headers

      expect(res[:result]).to eq "OK"

      expect(MailSpool.exceeded_payment.count).to eq 1
    end

    describe 'エラーパターンの検証' do
      it '未来日では入金できないこと' do
        params = default_params.dup
        params[:received_date] = '20221004'

        post rudy_confirm_repayment_path, params: params, headers: headers

        expect(res[:result]).to eq "NG"
        expect(res[:error]).to eq "invalid_date"
      end

      it 'repayment_idの重複でエラーになること' do
        params = default_params.dup

        post rudy_confirm_repayment_path, params: params, headers: headers
        expect(res[:result]).to eq "OK"

        post rudy_confirm_repayment_path, params: params, headers: headers
        expect(res[:result]).to eq "NG"
        expect(res[:error]).to eq "duplicate_repayment_id"
      end

      it '日付の不正フォーマットでエラーになること' do
        params = default_params.dup
        params[:received_date] = '2022012'

        post rudy_confirm_repayment_path, params: params, headers: headers

        expect(res[:result]).to eq "NG"
        expect(res[:error]).to eq "invalid_date"
      end

      it 'Contractor設定で無効' do
        contractor.update!(enable_rudy_confirm_payment: false)
        params = default_params.dup

        post rudy_confirm_repayment_path, params: params, headers: headers

        expect(res[:result]).to eq "NG"
        expect(res[:error]).to eq "disabled_contractor_setting"
      end
    end

    describe '宛名の検証' do
      before do
        FactoryBot.create(:contractor_user, contractor: contractor, email: 'test1@a.com')
        FactoryBot.create(:contractor_user, contractor: contractor, email: 'test2@a.com')
        FactoryBot.create(:contractor_user, contractor: contractor, email: 'test2@a.com')
        FactoryBot.create(:contractor_user, contractor: contractor, email: 'test3@a.com')
      end

      it 'ContractorUserが複数の場合は宛名がまとめられること。重複は除外されること' do
        params = default_params.dup

        post rudy_confirm_repayment_path, params: params, headers: headers

        expect(res[:result]).to eq "OK"

        expect(MailSpool.receive_payment.count).to eq 1
        expect(MailSpool.receive_payment.first.send_email_addresses.count).to eq 3
        expect(MailSpool.receive_payment.first.email_addresses_str).to eq 'test1@a.com, test2@a.com, test3@a.com'
      end
    end

    context 'Paymentあり' do
      before do
        FactoryBot.create(:installment,
          payment: FactoryBot.create(:payment, :next_due, due_ymd: '20221015', contractor: contractor),
          order: FactoryBot.create(:order, :inputed_date, purchase_ymd: '20220915', contractor: contractor),
          due_ymd: '20221015', principal: 100,
        )

        FactoryBot.create(:contractor_user, contractor: contractor, email: 'test@a.com')
      end

      it '入金処理ができること' do
        params = default_params.dup

        post rudy_confirm_repayment_path, params: params, headers: headers

        expect(res[:result]).to eq "OK"
        expect(Payment.first.paid?).to eq true

        expect(SmsSpool.receive_payment.count).to eq 1
        expect(MailSpool.receive_payment.count).to eq 1
      end

      it 'exceededの発生でメールが送信されること' do
        params = default_params.dup
        params[:received_amount] = 1000

        post rudy_confirm_repayment_path, params: params, headers: headers

        expect(res[:result]).to eq "OK"

        expect(MailSpool.exceeded_payment.count).to eq 1
        expect(MailSpool.exceeded_payment.first.mail_body.include?('Due : 15 / 10 / 2022')).to eq true
      end

      it 'exceededが発生しない場合はメールが送信されないこと' do
        params = default_params.dup
        params[:received_amount] = 1

        post rudy_confirm_repayment_path, params: params, headers: headers

        expect(res[:result]).to eq "OK"

        expect(MailSpool.exceeded_payment.count).to eq 0
      end

      describe 'Paymentに複数installments' do
        before do
          FactoryBot.create(:installment,
            payment: Payment.find_by(due_ymd: '20221015'),
            order: FactoryBot.create(:order, :inputed_date, purchase_ymd: '20220915', contractor: contractor),
            due_ymd: '20221015', principal: 200,
          )
        end

        it '重複する日付は除外されること' do
          params = default_params.dup
          params[:received_amount] = 1000

          post rudy_confirm_repayment_path, params: params, headers: headers

          expect(res[:result]).to eq "OK"

          expect(ReceiveAmountDetail.count).to eq 2
          expect(MailSpool.exceeded_payment.count).to eq 1
          expect(MailSpool.exceeded_payment.first.mail_body.include?('Due : 15 / 10 / 2022')).to eq true
          expect(MailSpool.exceeded_payment.first.mail_body.include?('Due : 15 / 10 / 2022, 15 / 10 / 2022')).to eq false
        end
      end

      describe '複数のPayment' do
        before do
          FactoryBot.create(:installment,
            payment: FactoryBot.create(:payment, :next_due, due_ymd: '20220930', contractor: contractor),
            order: FactoryBot.create(:order, :inputed_date, purchase_ymd: '20220831', contractor: contractor),
            due_ymd: '20220831', principal: 200,
          )
        end

        it '複数のDue Dateが表示されること' do
          params = default_params.dup
          params[:received_amount] = 1000

          post rudy_confirm_repayment_path, params: params, headers: headers

          expect(res[:result]).to eq "OK"

          expect(ReceiveAmountDetail.count).to eq 2
          expect(MailSpool.exceeded_payment.count).to eq 1
          expect(MailSpool.exceeded_payment.first.mail_body.include?('Due : 30 / 09 / 2022, 15 / 10 / 2022')).to eq true
        end
      end
    end
  end
end
