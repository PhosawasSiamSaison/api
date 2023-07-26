# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Batch::SavePurchaseData do
  before do
    FactoryBot.create(:system_setting)
  end

  describe '実行日時' do
    let(:dealer) { Dealer.first }

    context '月末' do
      before do
        FactoryBot.create(:dealer)
        FactoryBot.create(:business_day, business_ymd: '20190228') 
      end

      it 'バッチが実行されること' do
        Batch::SavePurchaseData.exec

        expect(dealer.dealer_purchase_of_months.count).to eq 1
      end
    end

    context '月初' do
      before do
        FactoryBot.create(:dealer)
        FactoryBot.create(:business_day, business_ymd: '20190301') 
      end

      it 'バッチが実行されないこと' do
        Batch::SavePurchaseData.exec

        expect(dealer.dealer_purchase_of_months.count).to eq 0
      end
    end

    context '月末の前日' do
      before do
        FactoryBot.create(:dealer)
        FactoryBot.create(:business_day, business_ymd: '20190227') 
      end

      it 'バッチが実行されないこと' do
        Batch::SavePurchaseData.exec

        expect(dealer.dealer_purchase_of_months.count).to eq 0
      end
    end
  end
end
