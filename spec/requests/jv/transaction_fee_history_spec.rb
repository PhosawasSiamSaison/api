require 'rails_helper'

RSpec.describe "Jv::TransactionFeeHistories", type: :request do
  let(:area) { FactoryBot.create(:area)}
  let(:create_user_auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:create_user) { create_user_auth_token.tokenable }
  let(:dealer) { FactoryBot.create(:dealer, tax_id: '1000000000001', area: area, dealer_code: 1,
    dealer_name: 'test dealer', status: 'active', bank_account: 'test bank', address: 'test address',
    create_user: create_user, update_user: create_user) }

  describe '#create_transaction_fee_history' do
    before do
      FactoryBot.create(:business_day)
      FactoryBot.create(:system_setting)
    end

    describe "Success Case" do
      let(:default_params) {
        {
          auth_token: create_user_auth_token.token,
          transaction_fee_history: {
            dealer_id: dealer.id,
            apply_ymd: '20190116',
            for_normal_rate: 2,
            for_government_rate: 2,
            for_sub_dealer_rate: 2,
            for_individual_rate: 2,
            reason: 'update transaction fee'
          }
        }
      }
      it "should create transaction_fee_history success" do
        post '/api/jv/transaction_fee_history/create_transaction_fee_history', params: default_params


        expect(res[:success]).to eq true
        new_transaction = TransactionFeeHistory.find_by(dealer_id: dealer.id)

        expect(new_transaction).to be_present
        expect(new_transaction.dealer_id).to eq default_params[:transaction_fee_history][:dealer_id]
        expect(new_transaction.apply_ymd).to eq default_params[:transaction_fee_history][:apply_ymd]
        expect(new_transaction.for_normal_rate).to eq default_params[:transaction_fee_history][:for_normal_rate]
        expect(new_transaction.for_government_rate).to eq default_params[:transaction_fee_history][:for_government_rate]
        expect(new_transaction.for_sub_dealer_rate).to eq default_params[:transaction_fee_history][:for_sub_dealer_rate]
        expect(new_transaction.for_individual_rate).to eq default_params[:transaction_fee_history][:for_individual_rate]
        expect(new_transaction.status).to eq "scheduled"
      end
    end

    describe "Failed Case" do
      it "should create transaction_fee_history failed (apply_ymd <= today_ymd)" do
        post '/api/jv/transaction_fee_history/create_transaction_fee_history', params: {
          auth_token: create_user_auth_token.token,
          transaction_fee_history: {
            dealer_id: dealer.id,
            apply_ymd: '20190101',
            for_normal_rate: 2,
            for_government_rate: 2,
            for_sub_dealer_rate: 2,
            for_individual_rate: 2,
            reason: 'update transaction fee'
          }
        }

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq(["Apply YMD must more than 20190115"])
        new_transaction = TransactionFeeHistory.find_by(dealer_id: dealer.id)

        expect(new_transaction).to be_nil
      end

      it "should create transaction_fee_history failed (reason can't be blank)" do
        post '/api/jv/transaction_fee_history/create_transaction_fee_history', params: {
          auth_token: create_user_auth_token.token,
          transaction_fee_history: {
            dealer_id: dealer.id,
            apply_ymd: '20190116',
            for_normal_rate: 2,
            for_government_rate: 2,
            for_sub_dealer_rate: 2,
            for_individual_rate: 2,
          }
        }

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq(["Reason can't be blank"])
        new_transaction = TransactionFeeHistory.find_by(dealer_id: dealer.id)

        expect(new_transaction).to be_nil
      end
    end
  end

  describe '#delete_transaction_fee_history' do
    describe "Success Case" do
      let(:transaction_fee_history) { 
        FactoryBot.create(:transaction_fee_history,
          dealer: dealer,
          for_normal_rate: 2,
          for_government_rate: 2,
          for_sub_dealer_rate: 2,
          for_individual_rate: 2
        )
      }
      before do
        FactoryBot.create(:business_day)
        FactoryBot.create(:system_setting)
      end
      let(:default_params) {
        {
          auth_token: create_user_auth_token.token,
          id: transaction_fee_history.id
        }
      }
      it "should delete transaction_fee_history success" do
        delete '/api/jv/transaction_fee_history/delete_transaction_fee_history', params: default_params

        expect(res[:success]).to eq true
      end
    end

    describe "Failed Case" do
      let(:transaction_fee_history) { 
        FactoryBot.create(:transaction_fee_history,
          dealer: dealer,
          for_normal_rate: 2,
          for_government_rate: 2,
          for_sub_dealer_rate: 2,
          for_individual_rate: 2,
          status: "active"
        )
      }
      let(:default_params) {
        {
          auth_token: create_user_auth_token.token,
          id: transaction_fee_history.id
        }
      }
      before do
        FactoryBot.create(:business_day)
        FactoryBot.create(:system_setting)
      end
      it "should delete transaction_fee_history failed (apply_ymd <= today_ymd)" do
        business_day = BusinessDay.first
        expect(transaction_fee_history.apply_ymd).to eq '20190116'
        business_day.update_ymd!('20190116')
        delete '/api/jv/transaction_fee_history/delete_transaction_fee_history', params: default_params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq("can't delete in use Transaction Fee History")
      end
    end
  end

  describe '#transaction_fees' do
    before do
      FactoryBot.create(:system_setting)
      FactoryBot.create(:business_day, business_ymd: '20190215')
      FactoryBot.create(:transaction_fee_history,
        dealer: dealer,
        apply_ymd: "20190216",
        for_normal_rate: 2,
        for_government_rate: 2,
        for_sub_dealer_rate: 2,
        for_individual_rate: 2
      )
      old_transaction = FactoryBot.build(:transaction_fee_history,
        dealer: dealer,
        apply_ymd: "20190215",
        for_normal_rate: 2,
        for_government_rate: 2,
        for_sub_dealer_rate: 2,
        for_individual_rate: 2,
        status: "active"
      )

      old_transaction.save(validate: false)

      delete_transaction = FactoryBot.build(:transaction_fee_history,
        dealer: dealer,
        apply_ymd: "20190201",
        for_normal_rate: 2,
        for_government_rate: 2,
        for_sub_dealer_rate: 2,
        for_individual_rate: 2,
        status: "deleted",
        deleted: 1
      )

      delete_transaction.save(validate: false)
    end

    it 'get transaction_fees correctly (only active and scheduled)' do
      get '/api/jv/transaction_fee_history/transaction_fees', params: {
        auth_token: create_user_auth_token.token,
        dealer_id: dealer.id
      }
      
      expect(res[:success]).to eq true

      transaction_fees = res[:transaction_fees]
      expect(transaction_fees.count).to eq(2)
      expect(transaction_fees[0][:apply_ymd]).to eq("20190216")
      expect(transaction_fees[0][:status]).to eq("scheduled")
      expect(transaction_fees[1][:apply_ymd]).to eq("20190215")
      expect(transaction_fees[1][:status]).to eq("active")
    end
  end

  describe '#transaction_fee_histories' do
    before do
      FactoryBot.create(:system_setting)
      FactoryBot.create(:business_day, business_ymd: '20190215')
      FactoryBot.create(:transaction_fee_history,
        dealer: dealer,
        apply_ymd: "20190216",
        for_normal_rate: 2,
        for_government_rate: 2,
        for_sub_dealer_rate: 2,
        for_individual_rate: 2
      )
      old_transaction = FactoryBot.build(:transaction_fee_history,
        dealer: dealer,
        apply_ymd: "20190215",
        for_normal_rate: 2,
        for_government_rate: 2,
        for_sub_dealer_rate: 2,
        for_individual_rate: 2,
        status: "active"
      )

      old_transaction.save(validate: false)

      delete_transaction = FactoryBot.build(:transaction_fee_history,
        dealer: dealer,
        apply_ymd: "20190201",
        for_normal_rate: 2,
        for_government_rate: 2,
        for_sub_dealer_rate: 2,
        for_individual_rate: 2,
        status: "deleted",
        deleted: 1
      )

      delete_transaction.save(validate: false)
    end

    it 'get transaction_fee_histories correctly (all status)' do
      get '/api/jv/transaction_fee_history/transaction_fee_histories', params: {
        auth_token: create_user_auth_token.token,
        dealer_id: dealer.id
      }
      
      expect(res[:success]).to eq true

      transaction_fees = res[:transaction_fee_histories]
      expect(transaction_fees.count).to eq(3)
      expect(transaction_fees[0][:apply_ymd]).to eq("20190216")
      expect(transaction_fees[0][:status]).to eq("scheduled")
      expect(transaction_fees[1][:apply_ymd]).to eq("20190215")
      expect(transaction_fees[1][:status]).to eq("active")
      expect(transaction_fees[2][:apply_ymd]).to eq("20190201")
      expect(transaction_fees[2][:status]).to eq("deleted")
    end
  end
end
