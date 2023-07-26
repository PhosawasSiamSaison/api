# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DealerPaymentFileCreator, type: :model do
  let(:normal_contractor) {     FactoryBot.create(:contractor, contractor_type: :normal ) }
  let(:sub_dealer_contractor) { FactoryBot.create(:contractor, contractor_type: :sub_dealer) }
  let(:government_contractor) { FactoryBot.create(:contractor, contractor_type: :government) }
  let(:individual_contractor) { FactoryBot.create(:contractor, contractor_type: :individual) }

  let(:gh_dealer) { FactoryBot.create(:global_house_dealer)}

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20190115')
  end

  describe 'split_zip_orders' do
    let(:input_ymd) { '20210901' }

    context '複数オーダー' do
      before do
        FactoryBot.create(:order, dealer: gh_dealer, contractor: normal_contractor,     input_ymd: input_ymd)
        FactoryBot.create(:order, dealer: gh_dealer, contractor: government_contractor, input_ymd: input_ymd)
        FactoryBot.create(:order, dealer: gh_dealer, contractor: sub_dealer_contractor, input_ymd: input_ymd)
        FactoryBot.create(:order, dealer: gh_dealer, contractor: individual_contractor, input_ymd: input_ymd)
      end

      it 'それぞれのオーダーが正しく取得できること' do
        orders = gh_dealer.orders.payment_target_orders(input_ymd) + []
        orders_data = DealerPaymentFileCreator.new.send('split_zip_orders', orders)

        expect(orders_data.length).to eq 4

        normal_orders = orders_data[:normal_orders]
        expect(normal_orders.length).to eq 1

        sub_dealer_orders = orders_data[:sub_dealer_orders]
        expect(sub_dealer_orders.length).to eq 1

        government_orders = orders_data[:government_orders]
        expect(government_orders.length).to eq 1

        individual_orders = orders_data[:individual_orders]
        expect(individual_orders.length).to eq 1

        # normal
        expect(normal_orders.first.contractor.normal?).to eq true

        # sub_dealer
        expect(sub_dealer_orders.first.contractor.sub_dealer?).to eq true

        # government
        expect(government_orders.first.contractor.government?).to eq true

        # individual
        expect(individual_orders.first.contractor.individual?).to eq true
      end
    end

    context '単品オーダー' do
      before do
        FactoryBot.create(:order, dealer: gh_dealer, contractor: normal_contractor, input_ymd: input_ymd)
      end

      it '値がある場合のみキーが存在すること' do
        orders = gh_dealer.orders.payment_target_orders(input_ymd) + []
        orders_data = DealerPaymentFileCreator.new.send('split_zip_orders', orders)

        expect(orders_data.length).to eq 1
      end

      it '最初に取得したオーダーが保持されること' do
        orders = gh_dealer.orders.payment_target_orders(input_ymd) + []

        dealer_payment_file_creator = DealerPaymentFileCreator.new

        orders_data1 = dealer_payment_file_creator.send('split_zip_orders', orders)
        orders_data2 = dealer_payment_file_creator.send('split_zip_orders', Order.none)

        expect(orders_data1).to eq orders_data2
      end
    end
  end

  describe 'can_orders_split?' do
    let(:input_ymd) { '20210901' }

    context '単体オーダー' do
      before do
        FactoryBot.create(:order, dealer: gh_dealer, contractor: normal_contractor, input_ymd: input_ymd)
      end

      it 'エラーにならないこと' do
        orders = gh_dealer.orders.payment_target_orders(input_ymd) + []
        expect(DealerPaymentFileCreator.new.send('can_orders_split?', orders)).to eq false
      end
    end
  end
end
