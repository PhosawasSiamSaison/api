require 'rails_helper'

RSpec.describe Contractor::OrderDetailController, type: :controller do
  before do
    FactoryBot.create(:system_setting)
  end

  describe '#order_detail' do
    let(:auth_token) { FactoryBot.create(:auth_token, :contractor) }
    let(:contractor) { auth_token.tokenable.contractor }
    let(:order) {
      FactoryBot.create(:order, contractor: contractor, purchase_ymd: '20190101', purchase_amount: 3000)
    }

    describe '正常値' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190101')
        FactoryBot.create(:installment, order: order, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it "値が取得できること" do
        params = {
          auth_token: auth_token.token,
          order_id: order.id
        }

        get :order_detail, params: params
        expect(response).to have_http_status(:success)
        expect(res[:success]).to eq true
        expect(res[:order][:order_number]).to eq order.order_number
        expect(res[:order][:change_product_status].is_a?(Hash)).to be true
        expect(res[:order][:change_product_status][:code]).to eq 'unapply'
        expect(res[:order][:site]).to eq nil
      end
    end

    describe 'CPACオーダー' do
      let(:order) {
        FactoryBot.create(:order, :cpac, contractor: contractor, purchase_amount: 1000)
      }

      before do
        FactoryBot.create(:business_day, business_ymd: '20190101')
        FactoryBot.create(:installment, order: order, installment_number: 1,
          due_ymd: '20190215', principal: 1000, interest: 0)
      end

      it "値が取得できること" do
        params = {
          auth_token: auth_token.token,
          order_id: order.id
        }

        get :order_detail, params: params

        expect(res[:success]).to eq true
        expect(res[:order][:site].present?).to eq true
        expect(res[:order][:site][:site_code]).to eq order.site.site_code
        expect(res[:order][:site][:site_name]).to eq order.site.site_name
        expect(res[:order][:site][:site_credit_limit]).to eq order.site.site_credit_limit
        expect(res[:order][:site][:available_balance]).to eq order.site.available_balance
        expect(res[:order][:site][:closed]).to eq order.site.closed?
      end
    end
  end
end
