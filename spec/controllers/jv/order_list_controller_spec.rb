require 'rails_helper'

RSpec.describe Jv::OrderListController, type: :controller do

  describe '#search' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:default_params) {
      {
        auth_token: auth_token.token,
        search: {
          purchase: {
            from_ymd: '',
            to_ymd: ''
          },
          include_no_input_date: 'true',
          include_paid_up: 'true',
          include_canceled: 'true',
          tax_id: '',
          company_name: '',
          dealer_id: nil,
        },
        page: 1,
        per_page: 20
      }
    }

    describe '正常値' do
      before do
        FactoryBot.create(:order)
      end

      it "値が取得できること" do
        post :search, params: default_params
        expect(response).to have_http_status(:success)
        expect(res[:success]).to eq true

        order = res[:orders].first
        expect(order[:id]).to eq Order.first.id
        expect(order[:is_applying_change_product].to_s.present?).to eq true
        expect(order.has_key?(:is_product_changed)).to eq true
        expect(order[:belongs_to_second_dealer]).to eq false
      end
    end

    describe 'ソート' do
      before do
        FactoryBot.create(:order, purchase_ymd: '20190101', is_applying_change_product: false)
        FactoryBot.create(:order, purchase_ymd: '20190104', is_applying_change_product: true)
        FactoryBot.create(:order, purchase_ymd: '20190103', is_applying_change_product: false)
        FactoryBot.create(:order, purchase_ymd: '20190102', is_applying_change_product: true)
      end

      it "ローン変更の申請、日付、のソートになること" do
        post :search, params: default_params
        expect(res[:success]).to eq true

        expect(res[:orders][0][:purchase_ymd]).to eq '20190104'
        expect(res[:orders][1][:purchase_ymd]).to eq '20190102'
        expect(res[:orders][2][:purchase_ymd]).to eq '20190103'
        expect(res[:orders][3][:purchase_ymd]).to eq '20190101'
      end
    end

    describe 'SiteCode検索' do
      before do
        site1 = FactoryBot.create(:site, site_code: 'aaa')
        site2 = FactoryBot.create(:project_phase_site, site_code: 'bbb')

        FactoryBot.create(:order, :inputed_date, site: site1)
        FactoryBot.create(:order, :inputed_date, project_phase_site: site2)
      end

      it "通常SiteのCodeの検索で取得できること" do
        params = default_params.dup
        params[:search][:site_code] = 'aaa'

        post :search, params: params
        expect(res[:success]).to eq true

        expect(res[:orders].count).to eq 1
        order = res[:orders].first

        expect(order[:site_code]).to eq 'aaa'
        expect(order[:belongs_to_project_finance]).to eq false
      end

      it "PFのSiteのCodeの検索で取得できること" do
        params = default_params.dup
        params[:search][:site_code] = 'bbb'

        post :search, params: params
        expect(res[:success]).to eq true

        expect(res[:orders].count).to eq 1
        order = res[:orders].first

        expect(order[:site_code]).to eq 'bbb'
        expect(order[:belongs_to_project_finance]).to eq true
      end
    end
  end

  describe '#order_detail' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:order) {
      FactoryBot.create(:order, contractor: contractor, purchase_ymd: '20190101',
        purchase_amount: 3000,
        dealer: first_dealer, second_dealer: second_dealer, second_dealer_amount: 1)
    }

    describe '正常値' do
      let(:first_dealer) { FactoryBot.create(:dealer, dealer_name: 'fd') }
      let(:second_dealer) { FactoryBot.create(:dealer, dealer_name: 'sd') }

      before do
        FactoryBot.create(:business_day, business_ymd: '20190101')

        payment = FactoryBot.create(:payment, :not_due_yet, contractor: contractor,
          due_ymd: '20190215', total_amount: 3000)

        FactoryBot.create(:installment, order: order, payment: payment,
          installment_number: 1, due_ymd: '20190215', principal: 3000, interest: 0)
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
        expect(res[:order][:change_product_status].is_a?(Hash)).to eq true
        expect(res[:order][:change_product_status][:code]).to eq 'unapply'
        expect(res[:order].has_key?(:applied_change_product)).to eq true
        expect(res[:order][:belongs_to_second_dealer]).to eq true

        purchase_amount_info = res[:order][:purchase_amount_info]
        expect(purchase_amount_info[:amount]).to eq 3000

        first_dealer_info = purchase_amount_info[:first_dealer_info]
        expect(first_dealer_info[:dealer][:dealer_name]).to eq 'fd'
        expect(first_dealer_info[:amount]).to eq 2999
        second_dealer_info = purchase_amount_info[:second_dealer_info]
        expect(second_dealer_info[:dealer][:dealer_name]).to eq 'sd'
        expect(second_dealer_info[:amount]).to eq 1
      end
    end
  end

  describe '#cancel_order' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:order) { FactoryBot.create(:order, canceled_at: nil) }

    describe '正常値' do
      it "キャンセルできること" do
        params = {
          auth_token: auth_token.token,
          order_id: order.id
        }

        patch :cancel_order, params: params
        expect(response).to have_http_status(:success)
        expect(res[:success]).to eq true
        expect(order.reload.canceled_at.present?).to eq true
      end
    end

    describe 'エラー' do
      before do
        order.update!(is_applying_change_product: true)
      end

      it "エラーメッセージが返ること" do
        params = {
          auth_token: auth_token.token,
          order_id: order.id
        }

        patch :cancel_order, params: params
        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.is_applying_change_product')]
        expect(order.reload.canceled?).to eq false
      end
    end
  end

  describe 'download_csv' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }

    describe '正常値' do
      let(:order) { FactoryBot.create(:order) }

      it "csv取得がエラーにならないこと" do
        params = {
          auth_token: auth_token.token,
        }

        get :download_csv, params: params
        expect(response.header["Content-Type"]).to eq "text/csv"
      end
    end

    describe 'Changed' do
      before do
        # unapply
        FactoryBot.create(:order, purchase_ymd: '20200110', input_ymd: '20200110')
        # registered
        FactoryBot.create(:order, purchase_ymd: '20200109', input_ymd: '20200109',
          change_product_status: 'registered', product_changed_at: '2020-01-09 10:00:00')
        # approval
        FactoryBot.create(:order, purchase_ymd: '20200108', input_ymd: '20200108',
          change_product_status: 'approval', product_changed_at: '2020-01-08 10:00:00')
        # rejected
        FactoryBot.create(:order, purchase_ymd: '20200107', input_ymd: '20200107',
          change_product_status: 'rejected', product_changed_at: '2020-01-07 10:00:00')
      end

      it 'Changedの値が正しいこと' do
        params = {
          auth_token: auth_token.token,
        }

        get :download_csv, params: params

        csv_str = response.body.sub(/^\xEF\xBB\xBF/, '')
        csv_arr = CSV.parse(csv_str)

        # unapply
        expect(csv_arr[1][11]).to eq 'None'
        # registered
        expect(csv_arr[2][11]).to eq '2020-01-09 10:00:00'
        # approval
        expect(csv_arr[3][11]).to eq '2020-01-08 10:00:00'
        # rejected
        expect(csv_arr[4][11]).to eq 'Reject'
      end
    end

    describe 'Site' do
      let(:default_params) {
        {
          auth_token: auth_token.token,
        }
      }

      context 'PFのSite' do
        before do
          site = FactoryBot.create(:project_phase_site, site_code: 'aaa')
          FactoryBot.create(:order, :inputed_date, project_phase_site: site)
        end

        it '取得できること' do
          get :download_csv, params: default_params

          expect(format_csv[1][13]).to eq 'aaa'
          expect(format_csv[1][27]).to eq 'Y'
        end
      end

      context 'CPAC系ののSite' do
        before do
          site = FactoryBot.create(:site, site_code: 'aaa', is_project: false)
          FactoryBot.create(:order, :inputed_date, site: site)
        end

        it '取得できること' do
          get :download_csv, params: default_params

          expect(format_csv[1][13]).to eq 'aaa'
          expect(format_csv[1][27]).to eq 'N'
        end
      end

      context '旧Project系ののSite' do
        before do
          site = FactoryBot.create(:site, site_code: 'aaa', is_project: true)
          FactoryBot.create(:order, :inputed_date, site: site)
        end

        it '取得できること' do
          get :download_csv, params: default_params

          expect(format_csv[1][13]).to eq 'aaa'
          expect(format_csv[1][27]).to eq 'N'
        end
      end
    end
  end

  private
    def format_csv
      csv_str = response.body.sub(/^\xEF\xBB\xBF/, '')
      CSV.parse(csv_str)
    end
end
