require 'rails_helper'

RSpec.describe Jv::ReportingController, type: :controller do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: jv_user) }

  before do
    FactoryBot.create(:system_setting, is_downloading_csv: false)
  end

  describe 'send_due_basis_csv' do
    describe '正常値' do
      before do
        FactoryBot.create(:business_day)

        order = FactoryBot.create(:order, :inputed_date)
        payment = FactoryBot.create(:payment)
        FactoryBot.create(:installment, payment: payment, order: order)
      end

      it "Dealerの項目がないこと" do
        params = {
          auth_token: auth_token.token,
        }

        get :download_due_basis_csv, params: params
        expect(response.header["Content-Type"]).to eq "text/csv"

        csv_str = response.body.sub(/^\xEF\xBB\xBF/, '')
        csv_arr = CSV.parse(csv_str)

        expect(csv_arr[0].find{|col| col == 'Due Date'}.present?).to eq true
        expect(csv_arr[0].find{|col| col == 'Dealer Name'}.present?).to eq false
      end
    end

    describe '権限チェック' do
      before do
        jv_user.staff!
      end

      it 'エラーが返ること' do
        params = {
          auth_token: auth_token.token,
        }

        get :check_can_download, params: params

        expect(res[:errors]).to eq [I18n.t('error_message.permission_denied')]
      end
    end
  end

  describe 'check_can_download' do
    describe '権限チェック' do
      before do
        jv_user.staff!
      end

      it 'エラーが返ること' do
        params = {
          auth_token: auth_token.token,
        }

        get :check_can_download, params: params

        expect(res[:errors]).to eq [I18n.t('error_message.permission_denied')]
      end
    end

    describe 'ダウンロード中の排他制御' do
      before do
        SystemSetting.update!(is_downloading_csv: true)
      end

      it 'エラーが返ること' do
        params = {
          auth_token: auth_token.token,
        }

        get :check_can_download, params: params

        expect(res[:errors]).to eq [I18n.t('error_message.is_downloading_csv')]
      end
    end
  end
end
