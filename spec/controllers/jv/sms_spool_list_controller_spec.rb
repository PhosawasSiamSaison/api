require 'rails_helper'

RSpec.describe Jv::SmsSpoolListController, type: :controller do

  describe '#search ' do
    before do
      FactoryBot.create(:business_day, business_ymd: '20210102')
    end

    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:default_params) {
      {
        auth_token: auth_token.token,
        search: {
          mobile_number: "",
          company_name: "",
          user_name: "",
        }
      }
    }

    describe 'ContractorUserをdelete' do
      before do
        deleted_contractor_user = FactoryBot.create(:contractor_user, deleted: true)
        FactoryBot.create(:sms_spool, :done, contractor_user: deleted_contractor_user,
          updated_at: '2021-01-01 00:00:00')
      end

      it 'エラーにならないこと' do
        get :search, params: default_params

        expect(res[:success]).to eq true
      end
    end

    xdescribe 'SMS Typeの文言取得' do
      before do
        FactoryBot.create(:sms_spool, :done, message_type: :create_project_order,
          updated_at: '2021-01-01 00:00:00')
      end

      it '正しく取得できること' do
        get :search, params: default_params

        expect(res[:success]).to eq true
        sms = res[:sms_list].first
        expect(sms[:message_type][:label]).to eq I18n.t('enum.sms_spool.message_type.create_project_order')
        # 文言が定義されていること
        expect(sms[:message_type][:label].include?('translation missing')).to_not eq true
      end
    end
  end
end
