# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchTodayRepaymentList, type: :model do
  let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:default_params) {
    {
      auth_token: auth_token.token,
      search: {
        tax_id: "",
        company_name: "",
        repayment_status: "all"
      },
      page: 1,
      per_page: 30
    }
  }

  before do
    FactoryBot.create(:business_day, business_ymd: '20210131')
  end

  describe '全てのステータスのpaymentのデータ' do
    before do
      ## Over Due
      contractor = FactoryBot.create(:contractor, pool_amount: 0.0, check_payment: false)
      FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20201231')

      ## Upcoming Due
      # Today
      contractor = FactoryBot.create(:contractor, pool_amount: 0.0, check_payment: false)
      FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20210131')

      # early payment
      contractor = FactoryBot.create(:contractor, pool_amount: 0.0, check_payment: true)
      FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20210215')

      # exist exceeded
      contractor = FactoryBot.create(:contractor, pool_amount: 0.01, check_payment: false)
      FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20210215')

      ## Not Due Yet
      # Not Due Yet
      contractor = FactoryBot.create(:contractor, pool_amount: 0.0, check_payment: true)
      payment = FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20210315')
      order = FactoryBot.create(:order, :inputed_date, contractor: contractor)
      FactoryBot.create(:installment, order: order, payment: payment)

      # Not Input Date
      contractor = FactoryBot.create(:contractor, pool_amount: 0.0, check_payment: true)
      FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20210415')
    end

    context 'search.repayment_status: all' do
      let(:params) {
        _params = default_params
        _params[:search][:repayment_status] = 'all'
        _params
      }

      it '全てのステータスのpaymentが取得できること' do
        payments, _ = SearchTodayRepaymentList.new(params).call

        expect(payments.count).to eq 6
        # over due
        expect(payments.first.status).to eq 'over_due'

        # today due
        today_due_payment = payments.second
        expect(today_due_payment.due_ymd).to eq BusinessDay.today_ymd

        # early
        early_payment = payments.third
        expect(early_payment.status).to eq 'next_due'
        expect(early_payment.contractor.check_payment).to eq true

        # exist exceeded
        exist_exceeded_payment = payments.fourth
        expect(exist_exceeded_payment.status).to eq 'next_due'
        expect(exist_exceeded_payment.contractor.exceeded_amount).to be > 0.0

        ## Not Due Yet
        # Not Due Yet
        not_due_yet_payment = payments.fifth
        expect(not_due_yet_payment.status).to eq 'not_due_yet'
        expect(not_due_yet_payment.all_orders_input_ymd_blank?).to eq false

        # Not Input Date
        not_input_date_payment = payments[5]
        expect(not_input_date_payment.status).to eq 'not_due_yet'
        expect(not_input_date_payment.all_orders_input_ymd_blank?).to eq true
      end
    end

    context 'search.repayment_status: over_due' do
      let(:params) {
        _params = default_params
        _params[:search][:repayment_status] = 'over_due'
        _params
      }

      it 'over_dueステータスのpaymentのみが取得できること' do
        payments, _ = SearchTodayRepaymentList.new(params).call

        expect(payments.count).to eq 1
        # over due
        expect(payments.first.status).to eq 'over_due'
      end
    end

    context 'search.repayment_status: upcoming_due' do
      let(:params) {
        _params = default_params
        _params[:search][:repayment_status] = 'upcoming_due'
        _params
      }

      it 'upcoming_dueステータスのpaymentのみが取得できること' do
        payments, _ = SearchTodayRepaymentList.new(params).call

        expect(payments.count).to eq 3

        # today due
        today_due_payment = payments.first
        expect(today_due_payment.status).to eq 'next_due'
        expect(today_due_payment.due_ymd).to eq BusinessDay.today_ymd

        # early
        early_payment = payments.second
        expect(early_payment.contractor.check_payment).to eq true
        expect(early_payment.status).to eq 'next_due'

        # exist exceeded
        exist_exceeded_payment = payments.third
        expect(exist_exceeded_payment.status).to eq 'next_due'
        expect(exist_exceeded_payment.contractor.exceeded_amount).to eq 0.01
      end
    end

    context 'search.repayment_status: not_due_yet' do
      let(:params) {
        _params = default_params
        _params[:search][:repayment_status] = 'not_due_yet'
        _params
      }

      it 'on_dueステータスのpaymentのみが取得できること' do
        payments, _ = SearchTodayRepaymentList.new(params).call

        expect(payments.count).to eq 2

       # not due yet
        not_due_yet_payment = payments.first
        expect(not_due_yet_payment.contractor.check_payment).to eq true
        expect(not_due_yet_payment.status).to eq 'not_due_yet'
        expect(not_due_yet_payment.all_orders_input_ymd_blank?).to eq false

        # not input date
        not_input_date_payment = payments.second
        expect(not_input_date_payment.contractor.check_payment).to eq true
        expect(not_input_date_payment.status).to eq 'not_due_yet'
        expect(not_input_date_payment.all_orders_input_ymd_blank?).to eq true
      end
    end

    describe 'paging' do
      it '1ページ目が取得できること' do
        params = default_params
        params[:page] = 1
        params[:per_page] = 4

        payments, total_count = SearchTodayRepaymentList.new(params).call

        expect(payments.count).to eq 4
        expect(total_count).to eq 6
      end

      it '2ページ目が取得できること' do
        params = default_params
        params[:page] = 2
        params[:per_page] = 4

        payments, total_count = SearchTodayRepaymentList.new(params).call

        expect(payments.count).to eq 2
        expect(total_count).to eq 6
      end
    end

    describe 'search.tex_id' do
      before do
        contractor = FactoryBot.create(:contractor, tax_id: '2000000000000')
        FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: BusinessDay.today_ymd)
      end

      it '正しく取得できること' do
        params = default_params
        params[:search][:tax_id] = '2000000000000'

        payments, total_count = SearchTodayRepaymentList.new(params).call

        expect(payments.count).to eq 1
        expect(payments.first.contractor.tax_id).to eq '2000000000000'
      end
    end

    describe 'search.company_name' do
      before do
        contractor = FactoryBot.create(:contractor, en_company_name: 'en-company')
        FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: BusinessDay.today_ymd)
      end

      it '正しく取得できること' do
        params = default_params
        params[:search][:company_name] = 'en-'

        payments, total_count = SearchTodayRepaymentList.new(params).call

        expect(payments.count).to eq 1
        expect(payments.first.contractor.en_company_name).to eq 'en-company'
      end
    end
  end

  describe '1つのContractor' do
    let(:contractor) { FactoryBot.create(:contractor, pool_amount: 0.01, check_payment: true) }
    let(:params) {
      _params = default_params
      _params[:search][:repayment_status] = 'all'
      _params
    }

    describe '重複チェック' do
      before do
        # early payment
        FactoryBot.create(:evidence, contractor: contractor)
        FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190122')

        # on due payment
        FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190123')

        # over due payment
        FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20190121')
      end

      it 'exceededがある場合にpaymentが重複して取得されないこと' do
        payments, _ = SearchTodayRepaymentList.new(params).call

        expect(payments.count).to eq 3
      end
    end
  end

  describe '対象外のpaymentのデータ' do
    before do
      # 今日期限で支払済
      contractor = FactoryBot.create(:contractor, pool_amount: 0.01, check_payment: true)
      FactoryBot.create(:payment, :paid, contractor: contractor, due_ymd: '20210131')

      # next_due でpool_amount, エビデンスアップロード なし
      contractor = FactoryBot.create(:contractor, pool_amount: 0.0, check_payment: false)
      FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20210215')

      # 未来期限で支払済
      contractor = FactoryBot.create(:contractor, pool_amount: 0.01, check_payment: true)
      FactoryBot.create(:payment, :paid, contractor: contractor, due_ymd: '20210215')

      ## Not Due Yet
      # Not Due Yet でエビデンスアップロードとexceededなし
      contractor = FactoryBot.create(:contractor, pool_amount: 0.00, check_payment: false)
      payment = FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20210315')
      order = FactoryBot.create(:order, :inputed_date, contractor: contractor)
      FactoryBot.create(:installment, order: order, payment: payment)

      # Not Input Date でエビデンスアップロードとexceededなし
      contractor = FactoryBot.create(:contractor, pool_amount: 0.00, check_payment: false)
      FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20210415')
    end

    context 'search.repayment_status: all' do
      let(:params) {
        _params = default_params
        _params[:search][:repayment_status] = 'all'
        _params
      }

      it '対象外のpaymentは取得されないこと' do
        payments, _ = SearchTodayRepaymentList.new(params).call

        expect(payments.count).to eq 0
      end
    end
  end
end
