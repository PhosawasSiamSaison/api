require 'rails_helper'

RSpec.describe Contractor::ItemListController, type: :controller do
  before do
    FactoryBot.create(:business_day)
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)
  end

  let(:contractor_user) { FactoryBot.create(:contractor_user) }
  let(:contractor) { contractor_user.contractor }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: contractor_user).token }

  describe "GET #detail_list" do
    before do
      FactoryBot.create(:installment, order: order)
    end

    let(:site) { FactoryBot.create(:site, contractor: contractor) }
    let(:order) { FactoryBot.create(:order, :cpac, contractor: contractor, site: site) }

    it '正常に取得できること' do
      params = {
        auth_token: auth_token,
        order_id: order.id
      }

      get :detail_list, params: params
      expect(res[:success]).to eq true
      expect(res[:order][:items].first[:product_no].present?).to eq true
    end
  end
end
