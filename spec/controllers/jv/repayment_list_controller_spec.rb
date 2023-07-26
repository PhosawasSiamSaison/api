require 'rails_helper'

RSpec.describe Jv::RepaymentListController, type: :controller do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: jv_user) }
  let(:contractor) { FactoryBot.create(:contractor) }

  describe '#search' do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        search: {
          tax_id: "",
          company_name: "",
          due_date: {
            from_ymd: "",
            to_ymd: ""
          }
        },
        page: "1",
        per_page: "10"
      }.dup
    }

    describe 'レスポンス' do
      before do
        order1 = FactoryBot.create(:order, contractor: contractor)
        order2 = FactoryBot.create(:order, contractor: contractor)

        payment1 = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190115')
        payment2 = FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20190201')

        FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190115')
        FactoryBot.create(:installment, order: order2, payment: payment2, due_ymd: '20190201')
      end

      it '正常に値が取得できること' do
        get :search, params: default_params

        expect(res[:success]).to eq true
        expect(res[:payments].count).to eq 2
        expect(res[:total_count]).to eq 2
      end

      it 'pagingが正しいこと' do
        params = default_params
        params[:per_page] = 1

        # page 1
        params[:page] = 1
        get :search, params: params

        expect(res[:success]).to eq true
        expect(res[:payments].count).to eq 1
        expect(res[:payments].first[:status][:code]).to eq 'next_due'
        expect(res[:total_count]).to eq 2

        # page 2
        params[:page] = 2
        get :search, params: params

        expect(res[:success]).to eq true
        expect(res[:payments].count).to eq 1
        expect(res[:payments].first[:status][:code]).to eq 'not_due_yet'
        expect(res[:total_count]).to eq 2
      end
    end

    describe 'search' do
      describe 'due_date' do
        before do
          order = FactoryBot.create(:order, contractor: contractor)
          payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190115')
          FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190115')
        end

        it '範囲内' do
          params = default_params
          params[:search][:due_date][:from_ymd] = '20190115'
          params[:search][:due_date][:to_ymd] = '20190115'

          get :search, params: params

          expect(res[:success]).to eq true
          expect(res[:payments].count).to eq 1
          expect(res[:payments].first[:due_ymd]).to eq '20190115'
        end

        it 'from_ymdの範囲外' do
          params = default_params
          params[:search][:due_date][:from_ymd] = '20190116'
          params[:search][:due_date][:to_ymd] = '20190116'

          get :search, params: params

          expect(res[:success]).to eq true
          expect(res[:payments].count).to eq 0
        end

        it 'to_ymdの範囲外' do
          params = default_params
          params[:search][:due_date][:from_ymd] = '20190114'
          params[:search][:due_date][:to_ymd] = '20190114'

          get :search, params: params

          expect(res[:success]).to eq true
          expect(res[:payments].count).to eq 0
        end
      end

      describe 'status' do
        before do
          order1 = FactoryBot.create(:order, contractor: contractor)
          order2 = FactoryBot.create(:order, contractor: contractor)
          order3 = FactoryBot.create(:order, contractor: contractor)
          order4 = FactoryBot.create(:order, contractor: contractor)

          payment1 = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190115')
          payment2 = FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20190201')
          payment3 = FactoryBot.create(:payment, :paid, contractor: contractor, due_ymd: '20190215')
          payment4 = FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20190228')

          FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190115')
          FactoryBot.create(:installment, order: order2, payment: payment2, due_ymd: '20190201')
          FactoryBot.create(:installment, order: order3, payment: payment3, due_ymd: '20190215')
          FactoryBot.create(:installment, order: order4, payment: payment4, due_ymd: '20190228')
        end

        it 'all' do
          params = default_params
          params[:search][:status] = 'all'

          get :search, params: params

          expect(res[:success]).to eq true
          expect(res[:payments].count).to eq 2
        end

        it 'next_due' do
          params = default_params
          params[:search][:status] = 'next_due'

          get :search, params: params

          expect(res[:success]).to eq true
          expect(res[:payments].count).to eq 1
          expect(res[:payments].first[:status][:code]).to eq 'next_due'
        end

        it 'not_due_yet' do
          params = default_params
          params[:search][:status] = 'not_due_yet'

          get :search, params: params

          expect(res[:success]).to eq true
          expect(res[:payments].count).to eq 1
          expect(res[:payments].first[:status][:code]).to eq 'not_due_yet'
        end

        it '指定なし' do
          params = default_params
          params[:search][:status] = ''

          get :search, params: params

          expect(res[:success]).to eq true
          expect(res[:payments].count).to eq 2
        end
      end
    end
  end

  describe '#status_list' do
    it '正常に値が取得できること' do
      params = {
        auth_token: auth_token.token
      }
      get :status_list, params: params

      expect(res[:success]).to eq true
      expect(res[:list].count).to eq 3
    end
  end
end
