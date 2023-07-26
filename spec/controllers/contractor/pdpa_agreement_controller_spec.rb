require 'rails_helper'

RSpec.describe Contractor::PdpaAgreementController, type: :controller do
  let(:contractor_user) { FactoryBot.create(:contractor_user) }
  let(:contractor) { contractor_user.contractor }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: contractor_user) }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day)
  end

  describe '#submit_pdpa_agreement' do
    let(:pdpa_version) { PdpaVersion.first }
    let(:default_params) {
      {
        auth_token: auth_token.token,
        version: 1,
        agreed: true,
      }
    }

    before do
      FactoryBot.create(:pdpa_version, version: 1)
    end

    it '規約同意レコードが作成されること' do
      expect(contractor_user.agreed_latest_pdpa?).to eq false

      post :submit_pdpa_agreement, params: default_params

      expect(res[:success]).to eq true
      expect(contractor_user.agreed_latest_pdpa?).to eq true
    end

    context 'メールなし' do
      before do
        contractor_user.update!(email: nil)
      end

      it 'Email未設定でエラーにならないこと' do
        post :submit_pdpa_agreement, params: default_params

        expect(res[:success]).to eq true
      end
    end

    context 'メールあり' do
      before do
        contractor_user.update!(email: 'a@a.com')
      end

      it 'Email設定ずみで送信（spool作成）されること' do
        post :submit_pdpa_agreement, params: default_params

        expect(res[:success]).to eq true
        expect(MailSpool.pdpa_agree.first.present?).to eq true
      end
    end

    context '最新のpdpaをdis agree(agreed: 0)で持っている' do
      before do
        FactoryBot.create(:contractor_user_pdpa_version,
          contractor_user: contractor_user, pdpa_version: pdpa_version, agreed: 0)
      end

      it 'エラーにならないこと' do
        # 最新のpdpaの関連は持っでいるが同意していない状態を確認
        expect(contractor_user.pdpa_versions.latest?).to eq true
        expect(contractor_user.agreed_latest_pdpa?).to eq false

        post :submit_pdpa_agreement, params: default_params

        expect(res[:success]).to eq true
        expect(contractor_user.agreed_latest_pdpa?).to eq true

        # 既存の同意レコードが更新されていること（増えてないこと）
        expect(contractor_user.pdpa_versions.count).to eq 1
      end
    end
  end
end
