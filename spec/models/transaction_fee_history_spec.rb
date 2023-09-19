require 'rails_helper'

RSpec.describe TransactionFeeHistory, type: :model do
  let(:dealer) { FactoryBot.create(:dealer) }
  before do
    FactoryBot.create(:business_day)
    FactoryBot.create(:system_setting)
  end

  describe 'validation' do
    describe "nil" do
      let(:transaction_fee_history) { FactoryBot.build(:transaction_fee_history, dealer: dealer) }
      before do
        transaction_fee_history.for_normal_rate = nil
      end

      it "should get error message can't be blank" do
        transaction_fee_history.valid?
        expect(transaction_fee_history.errors.messages[:for_normal_rate]).to eq ["can't be blank"]
      end
    end

    describe "less than 0" do
      let(:transaction_fee_history) { FactoryBot.build(:transaction_fee_history, dealer: dealer) }
      before do
        transaction_fee_history.for_normal_rate = -0.01
      end

      it "should get error message must be greater than or equal to 0" do
        transaction_fee_history.valid?
        expect(transaction_fee_history.errors.messages[:for_normal_rate]).to eq ["must be greater than or equal to 0"]
      end
    end

    describe 'apply_ymd' do
      describe 'check business_day' do
        describe 'success case' do
          let(:transaction_fee_history) { FactoryBot.build(:transaction_fee_history, dealer: dealer) }

          it 'create history success (apply_ymd > business day)' do
            expect(transaction_fee_history.valid?).to eq true
          end
        end

        describe 'failed case' do
          let(:transaction_fee_history) { FactoryBot.build(:transaction_fee_history, dealer: dealer, apply_ymd: '20190115') }
  
          it 'create history failed (apply_ymd <= business day)' do
            expect(transaction_fee_history.valid?).to eq false
            expect(transaction_fee_history.errors.messages[:apply_ymd]).to eq ["must more than 20190115"]
          end

          it 'create history failed (apply_ymd uniq with some active record)' do
            FactoryBot.create(:transaction_fee_history, dealer: dealer)
            transaction_fee_history_1 = FactoryBot.build(:transaction_fee_history, dealer: dealer)
            expect(transaction_fee_history_1.valid?).to eq false
            expect(transaction_fee_history_1.errors.messages[:apply_ymd]).to eq ["already taken. Please delete current scheduled history to recreate."]
          end
        end
      end
    end
  end

  describe '#delete_history' do
    let(:transaction_fee_history) { 
      FactoryBot.build(:transaction_fee_history,
        dealer: dealer,
        for_normal_rate: 2,
        for_government_rate: 2,
        for_sub_dealer_rate: 2,
        for_individual_rate: 2,
      )
    }
    
    it 'delete history success' do
      transaction_fee_history.delete_history
      expect(transaction_fee_history.status).to eq("deleted")
      expect(transaction_fee_history.deleted).to eq(1)
    end
  end
end
