require 'rails_helper'

RSpec.describe Rudy::GetInstallmentInfoController, type: :request do

  describe "#call" do
    let(:dealer) { FactoryBot.create(:cbm_dealer) }
    let(:contractor) {
      FactoryBot.create(:contractor, main_dealer: dealer, approval_status: "qualified")
    }
    let(:eligibility) { FactoryBot.create(:eligibility, contractor: contractor) }

    before do
      FactoryBot.create(:contractor_user, contractor: contractor, rudy_auth_token: 'hoge')
    end

    context 'DealerLimitの設定あり' do
      before do
        FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer)

        # 対象外の商品の無効を設定
        Product.all.each do |product|
          next if [1,4,2,3].include?(product.product_key)

          FactoryBot.create(:available_product, :purchase, :cbm, :unavailable, "product#{product.product_key}".to_sym,
            contractor: contractor)
        end
      end

      it "正常に取得できること" do
        params = {
          tax_id: contractor.tax_id,
          dealer_code: dealer.dealer_code,
          amount: "1000000",
        }

        get rudy_get_installment_info_path, params: params, headers: headers

        expect(res[:result]).to eq 'OK'

        products = res[:products]

        # ソートが正しいこと
        expect(products.map{|product| product[:product_id]}).to eq [1,4,2,3]

        product1 = products.find{|product| product[:product_id] == 1}
        product2 = products.find{|product| product[:product_id] == 2}
        product3 = products.find{|product| product[:product_id] == 3}
        product4 = products.find{|product| product[:product_id] == 4}

        expect(product1[:total_amount]).to eq 1000000.0
        expect(product1[:installment_amounts].count).to eq 1
        expect(product1[:installment_amounts][0]).to eq 1000000.0

        expect(product2[:total_amount]).to eq 1025100.0
        expect(product2[:installment_amounts].count).to eq 3
        expect(product2[:installment_amounts][0]).to eq 341700.02
        expect(product2[:installment_amounts][1]).to eq 341699.99

        expect(product3[:total_amount]).to eq 1044200.0
        expect(product3[:installment_amounts].count).to eq 6
        expect(product3[:installment_amounts][0]).to eq 174033.4
        expect(product3[:installment_amounts][1]).to eq 174033.32

        expect(product4[:total_amount]).to eq 1024600.0
        expect(product4[:installment_amounts].count).to eq 1
        expect(product4[:installment_amounts][0]).to eq 1024600.0
      end
    end

    it "dealer_limitなしでエラーにならないこと" do
      params = {
        tax_id: contractor.tax_id,
        dealer_code: dealer.dealer_code,
        amount: "1000000",
      }

      get rudy_get_installment_info_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'
    end
  end

  describe "demo" do
    it 'デモ用のトークンでデモ用レスポンスが返ること' do
      params = {
        tax_id: "1234567890111",
        dealer_code: "1234",
      }

      get rudy_get_installment_info_path, params: params, headers: demo_token_headers
      expect(res[:result]).to eq "OK"
    end
  end
end
