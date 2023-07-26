require 'rails_helper'

RSpec.describe Jv::CommonController, type: :controller do
  describe "POST #header_info" do
    before do
      FactoryBot.create(:business_day)
    end

    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:token) { jv_user.auth_tokens.create!(token: 'hoge').token }

    it "正常に取得ができること" do
      params = {
          auth_token: token
      }

      get :header_info, params: params
      expect(response).to have_http_status(:success)

      expect(res[:success]).to eq true
      expect(res[:login_user][:id]).to eq jv_user.id
      expect(res[:login_user][:user_name]).to eq jv_user.user_name
      expect(res[:login_user][:full_name]).to eq jv_user.full_name

      expect(res[:business_ymd]).to eq BusinessDay.first.business_ymd
    end
  end

  describe 'dealers 取得' do
    before do
      FactoryBot.create(:business_day)
      FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer1')
      FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer2')
      FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer3')
      FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer4', status: 'inactive')

    end

    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:token) { jv_user.auth_tokens.create!(token: 'hoge').token }
    let(:area) { FactoryBot.create(:area) }

    it "active な dealers が正常に取得ができること" do
      params = {
          auth_token: token
      }
      get :dealers, params: params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:dealers].count).to eq 3
    end
  end

  describe '#products' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv)}

    it "正常に取得できること" do
      params = {
          auth_token: auth_token.token
      }
      get :products, params: params

      expect(res[:success]).to eq true
      expect(res[:products].count).to_not eq 0

      product = res[:products].first
      expect(product.has_key?(:id)).to eq true
      expect(product.has_key?(:product_key)).to eq true
      expect(product.has_key?(:product_name)).to eq true
    end
  end

  describe 'item_list' do
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:token) { jv_user.auth_tokens.create!(token: 'hoge').token }
    let(:order) { Order.first }

    context '正常値' do
      before do
        FactoryBot.create(:order)
      end

      it '成功すること' do
        params = {
          auth_token: token,
          order_id: order.id,
          page: 1,
          per_page: 10,
        }

        get :item_list, params: params

        expect(response).to have_http_status(:success)
        expect(res[:success]).to eq true
        expect(res[:order].present?).to eq true
        expect(res[:order][:order_number]).to eq order.order_number
        expect(res[:order][:purchase_ymd]).to eq order.purchase_ymd
        expect(res[:order][:dealer].present?).to eq true
        expect(res[:order][:dealer][:id]).to eq order.dealer.id
        expect(res[:order][:dealer][:dealer_code]).to eq order.dealer.dealer_code
        expect(res[:order][:dealer][:dealer_name]).to eq order.dealer.dealer_name
        expect(res[:order][:items].present?).to eq true
        expect(res[:order][:items].count).to eq 3
        expect(res[:order][:items].first[:item_name]).to eq "sample 1"
        expect(res[:order][:items].first[:item_quantity]).to eq 1.0
        expect(res[:order][:items].first[:item_unit_price]).to eq 1000.0
        expect(res[:order][:items].first[:item_net_amount]).to eq 1000.0
        expect(res[:order][:total_count]).to eq 3
      end
    end

    context 'paging' do
      before do
        FactoryBot.create(:order)
      end

      it 'page1' do
        params = {
          auth_token: token,
          order_id: order.id,
          page: 1,
          per_page: 1,
        }

        get :item_list, params: params

        expect(res[:success]).to eq true
        expect(res[:order][:items].first[:item_name]).to eq "sample 1"
        expect(res[:order][:total_count]).to eq 3
      end

      it 'page2' do
        params = {
          auth_token: token,
          order_id: order.id,
          page: 3,
          per_page: 1,
        }

        get :item_list, params: params

        expect(res[:success]).to eq true
        expect(res[:order][:items].first[:item_name]).to eq "sample 3"
        expect(res[:order][:total_count]).to eq 3
      end
    end
  end

  describe 'detail_list' do
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:token) { jv_user.auth_tokens.create!(token: 'hoge').token }
    let(:order) { Order.first }

    context '正常値' do
      before do
        FactoryBot.create(:order, :cpac)
      end

      it '成功すること' do
        params = {
          auth_token: token,
          order_id: order.id,
          page: 1,
          per_page: 10,
        }

        get :detail_list, params: params

        expect(response).to have_http_status(:success)
        expect(res[:success]).to eq true
        expect(res[:order].present?).to eq true
        expect(res[:order][:order_number]).to eq order.order_number
        expect(res[:order][:purchase_ymd]).to eq order.purchase_ymd
        expect(res[:order][:dealer].present?).to eq true
        expect(res[:order][:dealer][:id]).to eq order.dealer.id
        expect(res[:order][:dealer][:dealer_code]).to eq order.dealer.dealer_code
        expect(res[:order][:dealer][:dealer_name]).to eq order.dealer.dealer_name
        expect(res[:order][:items].present?).to eq true
        expect(res[:order][:items].first[:product_no].present?).to eq true
      end
    end

    context 'paging' do
      before do
        FactoryBot.create(:order)
      end

      it 'page1' do
        params = {
          auth_token: token,
          order_id: order.id,
          page: 1,
          per_page: 1,
        }

        get :item_list, params: params

        expect(res[:success]).to eq true
        expect(res[:order][:items].first[:item_name]).to eq "sample 1"
        expect(res[:order][:total_count]).to eq 3
      end

      it 'page2' do
        params = {
          auth_token: token,
          order_id: order.id,
          page: 3,
          per_page: 1,
        }

        get :item_list, params: params

        expect(res[:success]).to eq true
        expect(res[:order][:items].first[:item_name]).to eq "sample 3"
        expect(res[:order][:total_count]).to eq 3
      end
    end
  end

  describe '#change_product_schedule' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:jv_user) { auth_token.tokenable }
    let(:order) { Order.first }
    let(:product1) { Product.find_by(product_key: 1) }
    let(:product2) { Product.find_by(product_key: 2) }

    context '登録可能(申請なし)' do
      before do
        FactoryBot.create(:system_setting)
        FactoryBot.create(:business_day, business_ymd: '20190215')

        FactoryBot.create(:order, :inputed_date, product: product1, purchase_ymd: '20190115')
        FactoryBot.create(:installment, order: order, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it 'product_keyがnullでafterが空になること' do
        params = {
          auth_token: auth_token.token,
          order_id: order.id,
          product_key: nil
        }

        get :change_product_schedule, params: params
        expect(res[:success]).to eq true

        expect(res[:change_product_status][:code]).to eq 'unapply'
        expect(res[:before][:count]).to eq order.installment_count
        expect(res[:before][:schedule].first[:amount]).to eq order.purchase_amount
        expect(res[:before][:schedule].first[:amount].is_a?(Float)).to eq true
        expect(res[:before][:schedule].first[:due_ymd]).to eq order.first_due_ymd
        expect(res[:after][:count]).to eq 0
        expect(res[:after][:schedule]).to eq []
        expect(res[:after][:total_amount]).to eq 0.0

        expect(res[:is_applying]).to eq false
        expect(res[:can_register]).to eq false
        expect(res[:messages]).to eq []
        expect(res[:changed_at]).to eq nil
        expect(res[:changed_user_name]).to eq nil
      end

      it 'product_keyが指定でafterに値が入ること' do
        params = {
          auth_token: auth_token.token,
          order_id: order.id,
          product_key: 2
        }

        get :change_product_schedule, params: params
        expect(res[:success]).to eq true

        expect(res[:change_product_status][:code]).to eq 'unapply'
        expect(res[:before][:count]).to eq order.installment_count
        expect(res[:before][:schedule].first[:amount]).to eq order.purchase_amount
        expect(res[:before][:schedule].first[:amount].is_a?(Float)).to eq true
        expect(res[:before][:schedule].first[:due_ymd]).to eq order.first_due_ymd
        expect(res[:after][:count]).to eq product2.number_of_installments
        expect(res[:after][:schedule].is_a?(Array)).to eq true
        expect(res[:after][:schedule].count).to eq product2.number_of_installments
        expect(res[:after][:schedule].first[:due_ymd].present?).to eq true
        expect(res[:after][:schedule].first[:amount].present?).to eq true
        expect(res[:after][:schedule].first[:amount].is_a?(Float)).to eq true
        expect(res[:after][:total_amount].is_a?(Float)).to eq true

        expect(res[:is_applying]).to eq false
        expect(res[:can_register]).to eq true
        expect(res[:messages]).to eq []
        expect(res[:changed_at]).to eq nil
        expect(res[:changed_user_name]).to eq nil
      end
    end

    context '申請あり' do
      before do
        FactoryBot.create(:system_setting)
        FactoryBot.create(:business_day, business_ymd: '20190215')
        # 申請ずみ
        FactoryBot.create(:order, :applied_change_product, :inputed_date, product: product1,
          purchase_ymd: '20190115')


        FactoryBot.create(:installment, order: order, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it '承認ができないこと' do
        params = {
          auth_token: auth_token.token,
          order_id: order.id,
          product_key: 2
        }

        get :change_product_schedule, params: params
        expect(res[:success]).to eq true

        expect(res[:is_applying]).to eq true
        expect(res[:can_register]).to eq false
        expect(res[:messages]).to eq []
        expect(res[:changed_at]).to eq nil
        expect(res[:changed_user_name]).to eq nil
      end
    end

    context 'ローン変更済' do
      before do

        FactoryBot.create(:system_setting)
        FactoryBot.create(:business_day, business_ymd: '20190215')
        FactoryBot.create(:order, :inputed_date, product: product1, purchase_ymd: '20190115',
          change_product_status: :approval, change_product_memo: nil, purchase_amount: 100,
          product_changed_at: '2019-01-01 00:00:00', product_changed_user: auth_token.tokenable,
          applied_change_product: product2)
        FactoryBot.create(:installment, order: order, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it '正常に値が取得できること' do
        params = {
          auth_token: auth_token.token,
          order_id: order.id,
          product_key: 2
        }

        get :change_product_schedule, params: params
        expect(res[:success]).to eq true

        expect(res[:before][:schedule].first[:amount]).to eq 100
        expect(res[:before][:schedule].first[:due_ymd]).to eq '20190215'
        expect(res[:after][:schedule].first[:due_ymd]).to eq '20190215'

        expect(res[:is_applying]).to eq false
        expect(res[:can_register]).to eq false
        expect(res[:messages]).to eq []
        expect(res[:changed_at].present?).to eq true
        expect(res[:changed_user_name]).to eq auth_token.tokenable.full_name
      end
    end

    context 'input_ymdなし' do
      before do
        FactoryBot.create(:system_setting)
        FactoryBot.create(:business_day, business_ymd: '20190215')

        FactoryBot.create(:order, product: product1, purchase_ymd: '20190115')
        FactoryBot.create(:installment, order: order, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it '正常に値が取得できること' do
        params = {
          auth_token: auth_token.token,
          order_id: order.id,
          product_key: 2
        }

        get :change_product_schedule, params: params
        expect(res[:success]).to eq true

        expect(res[:before][:count]).to eq order.installment_count
        expect(res[:before][:schedule].first[:amount]).to eq order.purchase_amount
        expect(res[:before][:schedule].first[:amount].is_a?(Float)).to eq true
        expect(res[:before][:schedule].first[:due_ymd]).to eq order.first_due_ymd
        expect(res[:after][:count]).to eq product2.number_of_installments
        expect(res[:after][:schedule].is_a?(Array)).to eq true
        expect(res[:after][:schedule].count).to eq product2.number_of_installments
        expect(res[:after][:schedule].first[:due_ymd].present?).to eq true
        expect(res[:after][:schedule].first[:amount].present?).to eq true
        expect(res[:after][:schedule].first[:amount].is_a?(Float)).to eq true

        expect(res[:is_applying]).to eq false
        expect(res[:can_register]).to eq false
        expect(res[:messages]).to eq [I18n.t("error_message.no_input_date")]
        expect(res[:changed_at]).to eq nil
        expect(res[:changed_user_name]).to eq nil
      end
    end

    context '変更を許可なし' do
      let(:contractor) { FactoryBot.create(:contractor) }
      let(:product) { Product.find_by(product_key: 4) }
      let(:dealer) { FactoryBot.create(:cbm_dealer) }

      before do
        FactoryBot.create(:system_setting)
        FactoryBot.create(:business_day, business_ymd: '20190215')
        FactoryBot.create(:order, :inputed_date, contractor: contractor, product: product1,
          dealer: dealer, purchase_ymd: '20190115')
        FactoryBot.create(:installment, order: order, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)

        FactoryBot.create(:available_product, :cbm, :switch, contractor: contractor,
          product: product, available: false)
      end

      it '正常に値が取得できること' do
        params = {
          auth_token: auth_token.token,
          order_id: order.id,
          product_key: product.product_key,
        }

        get :change_product_schedule, params: params
        expect(res[:success]).to eq true

        expect(res[:is_applying]).to eq false
        expect(res[:can_register]).to eq false
      end
    end
  end

  describe '#register_change_product' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:product2) { Product.find_by(product_key: 2) }
    let(:order) {
      FactoryBot.create(:order, :inputed_date, contractor: contractor, purchase_ymd: '20190101',
        purchase_amount: 3000)
    }

    before do
      FactoryBot.create(:system_setting)
      FactoryBot.create(:business_day, business_ymd: '20190101')

      payment = FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20190215',
        total_amount: 3000)
      FactoryBot.create(:installment, order: order, payment: payment,
        installment_number: 1, due_ymd: '20190215', principal: 3000, interest: 0)
    end

    describe '正常値' do
      it "成功すること" do
        expect(order.can_apply_change_product?).to eq true
        expect(order.can_change_product?).to eq true
        expect(order.can_register_change_product?(product2)).to eq true
        expect(order.can_approval_change_product?).to eq false

        params = {
          auth_token: auth_token.token,
          order_id: order.id,
          product_key: 2
        }

        patch :register_change_product, params: params
        order.reload
        expect(response).to have_http_status(:success)
        expect(res[:success]).to eq true
        expect(order.installment_count).to eq 3
        expect(order.change_product_status).to eq 'registered'
        expect(order.is_applying_change_product).to eq false
        expect(order.product_changed_at.present?).to eq true
        expect(order.product_changed_user).to eq auth_token.tokenable

        expect(order.can_apply_change_product?).to eq false
        expect(order.can_change_product?).to eq false
        expect(order.can_register_change_product?(product2)).to eq false
        expect(order.can_approval_change_product?).to eq false
        expect(order.product_changed?).to eq true
      end
    end

    describe '期日チェック' do
      before do
        BusinessDay.update!(business_ymd: '20190216')
      end

      it "期限超えでもSwitchができること" do
        params = {
          auth_token: auth_token.token,
          order_id: order.id,
          product_key: 2
        }

        patch :register_change_product, params: params
        expect(res[:success]).to eq true
      end
    end

    describe 'Stale Object' do
      before do
        order.rejected!
      end

      it "stale_objectエラーが返ること" do
        params = {
          auth_token: auth_token.token,
          order_id: order.id,
          product_key: 2
        }

        patch :register_change_product, params: params
        order.reload
        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.stale_object_error')]
      end
    end

    describe 'ロールバック' do
      before do
        # Orderの値を不整合にする
        order.update_attribute(:purchase_amount, 0.01)
      end

      it "stale_objectエラーが返ること" do
        params = {
          auth_token: auth_token.token,
          order_id: order.id,
          product_key: 2
        }

        expect(order.reload.installments.count).to eq 1

        patch :register_change_product, params: params
        order.reload
        expect(res[:success]).to eq false

        expect(order.reload.installments.count).to eq 1
      end
    end

    describe '利用許可されていない' do
      let(:product) { Product.find_by(product_key: 2) }

      before do
        FactoryBot.create(:available_product, :cbm, :switch, contractor: contractor,
          product: product, available: false)
      end

      it "stale_objectエラーが返ること" do
        params = {
          auth_token: auth_token.token,
          order_id: order.id,
          product_key: product.product_key
        }

        patch :register_change_product, params: params
        order.reload
        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.stale_object_error')]
      end
    end

    describe '権限チェック' do
      let(:staff) { FactoryBot.create(:jv_user, user_type: :staff) }
      let(:staff_token) { FactoryBot.create(:auth_token, tokenable: staff).token }

      it "staffは購入できないこと" do
        params = {
          auth_token: staff_token,
          order_id: order.id,
          product_key: 2
        }

        patch :register_change_product, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.permission_denied')]
      end
    end
  end

  describe '#credit_limit_information' do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:jv_user) { auth_token.tokenable }

    before do
      eligibility = FactoryBot.create(:eligibility, contractor: contractor)
      FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility, limit_amount: 0)
    end

    it 'レコードのあるDealerTypeのis_enabledがtrueになること' do
      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
      }

      get :credit_limit_information, params: params
      expect(res[:success]).to eq true

      res[:eligibility][:dealer_type_limits].each{|dealer_type_limit|
        if dealer_type_limit[:dealer_type][:code] == 'cbm'
          expect(dealer_type_limit[:is_enabled]).to eq true
        else
          expect(dealer_type_limit[:is_enabled]).to eq false
        end
      }
    end
  end 
end
