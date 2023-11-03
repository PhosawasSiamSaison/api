# frozen_string_literal: true
# == Schema Information
#
# Table name: dealers
#
#  id                   :bigint(8)        not null, primary key
#  tax_id               :string(13)       not null
#  area_id              :integer          not null
#  dealer_type          :integer          not null
#  dealer_code          :string(20)       not null
#  for_normal_rate      :decimal(5, 2)    default(2.0), not null
#  for_government_rate  :decimal(5, 2)    default(1.75)
#  for_sub_dealer_rate  :decimal(5, 2)    default(1.5)
#  for_individual_rate  :decimal(5, 2)    default(1.5)
#  dealer_name          :string(50)
#  en_dealer_name       :string(50)
#  bank_account         :string(1000)
#  address              :string(1000)
#  interest_rate        :decimal(5, 2)
#  status               :integer          default("active"), not null
#  create_user_id       :integer
#  update_user_id       :integer
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

require 'rails_helper'

RSpec.describe Dealer, type: :model do
  describe 'validates' do
    let(:dealer) { FactoryBot.create(:dealer) }

    describe "nil" do
      before do
        dealer.for_normal_rate = nil
      end

      it 'エラーになること' do
        dealer.valid?
        expect(dealer.errors.messages[:for_normal_rate]).to eq ["can't be blank"]
      end
    end

    describe "0より少ない" do
      before do
        dealer.for_normal_rate = -0.01
      end

      it 'エラーになること' do
        dealer.valid?
        expect(dealer.errors.messages[:for_normal_rate]).to eq ["must be greater than or equal to 0"]
      end
    end
  end

  describe '#save_purchase_data' do
    let(:dealer1) { FactoryBot.create(:dealer) }
    let(:dealer2) { FactoryBot.create(:dealer) }
    let(:contractor1) { FactoryBot.create(:contractor) }
    let(:contractor2) { FactoryBot.create(:contractor) }

    before do
      eligibility1 = FactoryBot.create(:eligibility, contractor: contractor1)
      eligibility2 = FactoryBot.create(:eligibility, contractor: contractor2)

      FactoryBot.create(:dealer_limit, eligibility: eligibility1, dealer: dealer1)
      FactoryBot.create(:dealer_limit, eligibility: eligibility2, dealer: dealer2)
    end

    context '正常値' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190131')

        FactoryBot.create(:order, contractor: contractor1,
          dealer: dealer1, purchase_amount: 100, purchase_ymd: '20190102')
      end

      it '正しく登録されること' do
        dealer1.save_purchase_data

        expect(dealer1.dealer_purchase_of_months.count).to eq 1
        purchase_of_month = dealer1.dealer_purchase_of_months.first
        expect(purchase_of_month.month).to eq '201901'
        expect(purchase_of_month.purchase_amount).to eq 100
        expect(purchase_of_month.order_count).to eq 1
      end
    end

    context '注文をキャンセル' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190131')

        FactoryBot.create(:order, :canceled, contractor: contractor1,
          dealer: dealer1, purchase_amount: 100, purchase_ymd: '20190101')
      end

      it 'キャンセル分は除外されること' do
        dealer1.save_purchase_data

        expect(dealer1.dealer_purchase_of_months.count).to eq 1
        purchase_of_month = dealer1.dealer_purchase_of_months.first
        expect(purchase_of_month.month).to eq '201901'
        expect(purchase_of_month.purchase_amount).to eq 0
        expect(purchase_of_month.order_count).to eq 0
      end
    end

    context '対象のcontractor以外からの注文' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190131')

        FactoryBot.create(:order, contractor: contractor1,
          dealer: dealer1, purchase_amount: 100, purchase_ymd: '20190102')
        # contractorのmain_dealerはdealer2で、dealer1で購入
        FactoryBot.create(:order, contractor: contractor2,
          dealer: dealer1, purchase_amount: 200, purchase_ymd: '20190102')
      end

      it '全てのcontractorが対象になること' do
        dealer1.save_purchase_data

        expect(dealer1.dealer_purchase_of_months.count).to eq 1
        purchase_of_month = dealer1.dealer_purchase_of_months.first
        expect(purchase_of_month.month).to eq '201901'
        expect(purchase_of_month.purchase_amount).to eq 300
        expect(purchase_of_month.order_count).to eq 2
      end
    end
  end

  describe '#credit_limit_amount' do
    let(:dealer) { FactoryBot.create(:dealer) }

    context '正常値' do
      let(:contractor) { FactoryBot.create(:contractor) }

      before do
        eligibility = FactoryBot.create(:eligibility, contractor: contractor, limit_amount: 100)
        FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer, limit_amount: 10)
      end

      it '正しくが取得できること' do
        expect(dealer.credit_limit_amount).to eq 10.0
      end
    end

    context '複数のContractor' do
      let(:contractor1) { FactoryBot.create(:contractor) }
      let(:contractor2) { FactoryBot.create(:contractor) }

      before do
        eligibility1 = FactoryBot.create(:eligibility, contractor: contractor1, limit_amount: 10)
        eligibility2 = FactoryBot.create(:eligibility, contractor: contractor2, limit_amount: 20)

        FactoryBot.create(:dealer_limit, eligibility: eligibility1, dealer: dealer, limit_amount: 1)
        FactoryBot.create(:dealer_limit, eligibility: eligibility2, dealer: dealer, limit_amount: 2)
      end

      it '正しくが取得できること' do
        expect(dealer.credit_limit_amount).to eq 3.0
      end
    end

    describe 'Contractor承認ステータス' do
      let(:contractor1) { FactoryBot.create(:contractor, approval_status: :pre_registration) }
      let(:contractor2) { FactoryBot.create(:contractor, approval_status: :processing) }
      let(:contractor3) { FactoryBot.create(:contractor, approval_status: :qualified) }
      let(:contractor4) { FactoryBot.create(:contractor, approval_status: :rejected) }

      before do
        eligibility1 = FactoryBot.create(:eligibility, contractor: contractor1, limit_amount: 100)
        eligibility2 = FactoryBot.create(:eligibility, contractor: contractor2, limit_amount: 200)
        eligibility3 = FactoryBot.create(:eligibility, contractor: contractor3, limit_amount: 400)
        eligibility4 = FactoryBot.create(:eligibility, contractor: contractor4, limit_amount: 800)

        FactoryBot.create(:dealer_limit, eligibility: eligibility1, dealer: dealer, limit_amount: 10)
        FactoryBot.create(:dealer_limit, eligibility: eligibility2, dealer: dealer, limit_amount: 20)
        FactoryBot.create(:dealer_limit, eligibility: eligibility3, dealer: dealer, limit_amount: 40)
        FactoryBot.create(:dealer_limit, eligibility: eligibility4, dealer: dealer, limit_amount: 80)
      end

      it '承認済みのコントラクターのみが対象になること' do
        expect(dealer.credit_limit_amount).to eq 40.0
      end
    end
  end

  xdescribe '#payable_installments' do
    let(:dealer) { FactoryBot.create(:dealer) }

    describe 'Contractor承認ステータス' do
      let(:contractor1) { FactoryBot.create(:contractor, approval_status: :pre_registration) }
      let(:contractor2) { FactoryBot.create(:contractor, approval_status: :processing) }
      let(:contractor3) { FactoryBot.create(:contractor, approval_status: :qualified) }
      let(:contractor4) { FactoryBot.create(:contractor, approval_status: :rejected) }
      let(:order1) { FactoryBot.create(:order, contractor: contractor1) }
      let(:order2) { FactoryBot.create(:order, contractor: contractor2) }
      let(:order3) { FactoryBot.create(:order, contractor: contractor3) }
      let(:order4) { FactoryBot.create(:order, contractor: contractor4) }

      before do
        FactoryBot.create(:installment, order: order1, principal: 100)
        FactoryBot.create(:installment, order: order2, principal: 200)
        FactoryBot.create(:installment, order: order3, principal: 400)
        FactoryBot.create(:installment, order: order4, principal: 800)

        eligibility1 = FactoryBot.create(:eligibility, contractor: contractor1)
        eligibility2 = FactoryBot.create(:eligibility, contractor: contractor2)
        eligibility3 = FactoryBot.create(:eligibility, contractor: contractor3)
        eligibility4 = FactoryBot.create(:eligibility, contractor: contractor4)

        FactoryBot.create(:dealer_limit, eligibility: eligibility1, dealer: dealer)
        FactoryBot.create(:dealer_limit, eligibility: eligibility2, dealer: dealer)
        FactoryBot.create(:dealer_limit, eligibility: eligibility3, dealer: dealer)
        FactoryBot.create(:dealer_limit, eligibility: eligibility4, dealer: dealer)
      end

      it '承認済みのコントラクターのみが対象になること' do
        principal = dealer.payable_installments.map{|i| i.principal}.sum
        expect(principal).to eq 400.0
      end
    end
  end

  describe '#remaining_principal' do
    let(:dealer) { FactoryBot.create(:dealer) }

    context '正常値' do
      let(:contractor) { FactoryBot.create(:contractor) }
      let(:order) { FactoryBot.create(:order, contractor: contractor, dealer: dealer) }

      before do
        eligibility = FactoryBot.create(:eligibility, contractor: contractor)
        FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer)

        FactoryBot.create(:installment, order: order, principal: 100, paid_principal: 10)
        FactoryBot.create(:installment, :paid_up, order: order, principal: 100, paid_principal: 10)
      end

      it '正常に値が取得できること' do
        expect(dealer.remaining_principal).to eq 90.0
      end
    end
  end

  describe '#available_balance' do
    let(:dealer) { FactoryBot.create(:dealer) }

    context '正常値' do
      let(:contractor) { FactoryBot.create(:contractor) }
      let(:order) { FactoryBot.create(:order, contractor: contractor, dealer: dealer) }

      before do
        eligibility = FactoryBot.create(:eligibility, contractor: contractor, limit_amount: 1000)
        FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer, limit_amount: 500)

        FactoryBot.create(:installment, order: order, principal: 100, paid_principal: 0)
      end

      it '正常に値が取得できること' do
        expect(dealer.available_balance).to eq 400.0
      end
    end
  end

  describe '#in_use_count' do
    let(:dealer) { FactoryBot.create(:dealer) }

    context 'Orderなし' do
      before do
        FactoryBot.create(:contractor, create_dealer_limit: dealer)
      end

      it '0になること' do
        expect(dealer.contractors.in_use_order_contractor.count).to eq 0
      end
    end

    context '支払い中のOrder' do
      let(:contractor) { FactoryBot.create(:contractor, create_dealer_limit: dealer) }

      before do
        FactoryBot.create(:order, contractor: contractor)
      end

      it '1になること' do
        expect(dealer.contractors.in_use_order_contractor.count).to eq 1
      end
    end

    context '支払い完了のOrder' do
      let(:contractor) { FactoryBot.create(:contractor, create_dealer_limit: dealer) }

      before do
        FactoryBot.create(:order, :paid, contractor: contractor)
      end

      it '0になること' do
        expect(dealer.contractors.in_use_order_contractor.count).to eq 0
      end
    end

    describe 'approval_status' do
      let(:contractor11) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :pre_registration) }
      let(:contractor21) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :processing) }
      let(:contractor22) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :processing) }
      let(:contractor31) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :qualified) }
      let(:contractor32) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :qualified) }
      let(:contractor33) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :qualified) }
      let(:contractor34) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :qualified) }
      let(:contractor41) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :rejected) }
      let(:contractor42) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :rejected) }
      let(:contractor43) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :rejected) }
      let(:contractor44) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :rejected) }
      let(:contractor45) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :rejected) }
      let(:contractor46) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :rejected) }
      let(:contractor47) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :rejected) }
      let(:contractor48) { FactoryBot.create(:contractor, create_dealer_limit: dealer, approval_status: :rejected) }

      before do
        FactoryBot.create(:order, contractor: contractor11)
        FactoryBot.create(:order, contractor: contractor21)
        FactoryBot.create(:order, contractor: contractor22)
        FactoryBot.create(:order, contractor: contractor31)
        FactoryBot.create(:order, contractor: contractor32)
        FactoryBot.create(:order, contractor: contractor33)
        FactoryBot.create(:order, contractor: contractor34)
        FactoryBot.create(:order, contractor: contractor41)
        FactoryBot.create(:order, contractor: contractor42)
        FactoryBot.create(:order, contractor: contractor43)
        FactoryBot.create(:order, contractor: contractor44)
        FactoryBot.create(:order, contractor: contractor45)
        FactoryBot.create(:order, contractor: contractor46)
        FactoryBot.create(:order, contractor: contractor47)
        FactoryBot.create(:order, contractor: contractor48)
      end

      it 'qualifiedのみがカウントされること' do
        expect(dealer.in_use_count).to eq 4
      end
    end
  end

  describe '#cbm_group?' do
    it '正しいこと' do
      cbm_dealer_types = ['cbm', 'global_house', 'transformer', 'bigth', 'permsin', 'scgp','rakmao','cotto']

      # CBM系
      cbm_dealer_types.each do |dealer_type|
        expect(Dealer.new(dealer_type: dealer_type).cbm_group?).to eq true
      end

      # CBM系以外
      not_cbm_dealer_types = Dealer.dealer_types.keys - cbm_dealer_types
      not_cbm_dealer_types.each do |dealer_type|
        expect(Dealer.new(dealer_type: dealer_type).cbm_group?).to eq false
      end
    end
  end

  describe '#latest_for_normal_rate' do
    describe 'no history' do
      let(:dealer) { FactoryBot.create(:dealer) }
      it 'get latest_for_normal_rate correctly' do
        latest_for_normal_rate = dealer.latest_for_normal_rate
        expect(latest_for_normal_rate).to eq(dealer.for_normal_rate)
      end
    end

    describe 'with history' do
      let(:dealer) { FactoryBot.create(:dealer) }
      describe 'active history' do
        before do
          FactoryBot.create(:system_setting)
          FactoryBot.create(:business_day, business_ymd: '20190215')
          transaction = FactoryBot.build(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190215",
            for_normal_rate: 30,
            for_government_rate: 20,
            for_sub_dealer_rate: 20,
            for_individual_rate: 20,
            status: "active"
          )
          transaction.save(validate: false)
        end

        it 'get latest_for_normal_rate from latest history correctly' do
          latest_for_normal_rate = dealer.latest_for_normal_rate
          expect(latest_for_normal_rate).to eq(30)
        end
      end

      describe 'input_ymd history' do
        before do
          FactoryBot.create(:system_setting)
          FactoryBot.create(:business_day, business_ymd: '20190215')
          transaction = FactoryBot.build(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190215",
            for_normal_rate: 3,
            for_government_rate: 2,
            for_sub_dealer_rate: 2,
            for_individual_rate: 2,
            status: "active"
          )
          transaction.save(validate: false)

          delete_transaction = FactoryBot.build(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190201",
            for_normal_rate: 20,
            for_government_rate: 20,
            for_sub_dealer_rate: 20,
            for_individual_rate: 20,
            status: "retired",
          )
    
          delete_transaction.save(validate: false)
        end

        it 'get latest_for_normal_rate from latest history correctly' do
          latest_for_normal_rate = dealer.latest_for_normal_rate("20190214")
          expect(latest_for_normal_rate).to eq(20)
        end

        it 'should not get latest_for_normal_rate from latest history scheduled' do
          FactoryBot.create(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190301",
            for_normal_rate: 30,
            for_government_rate: 20,
            for_sub_dealer_rate: 20,
            for_individual_rate: 20,
          )

          latest_for_normal_rate = dealer.latest_for_normal_rate("20190301")
          expect(latest_for_normal_rate).to eq(3)
        end
      end
    end
  end

  describe '#latest_for_government_rate' do
    describe 'no history' do
      let(:dealer) { FactoryBot.create(:dealer) }
      it 'get latest_for_government_rate correctly' do
        latest_for_government_rate = dealer.latest_for_government_rate
        expect(latest_for_government_rate).to eq(dealer.for_government_rate)
      end
    end

    describe 'with history' do
      let(:dealer) { FactoryBot.create(:dealer) }
      describe 'active history' do
        before do
          FactoryBot.create(:system_setting)
          FactoryBot.create(:business_day, business_ymd: '20190215')
          transaction = FactoryBot.build(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190215",
            for_normal_rate: 30,
            for_government_rate: 20,
            for_sub_dealer_rate: 20,
            for_individual_rate: 20,
            status: "active"
          )
          transaction.save(validate: false)
        end

        it 'get latest_for_government_rate from latest history correctly' do
          latest_for_government_rate = dealer.latest_for_government_rate
          expect(latest_for_government_rate).to eq(20)
        end
      end

      describe 'input_ymd history' do
        before do
          FactoryBot.create(:system_setting)
          FactoryBot.create(:business_day, business_ymd: '20190215')
          transaction = FactoryBot.build(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190215",
            for_normal_rate: 3,
            for_government_rate: 2,
            for_sub_dealer_rate: 2,
            for_individual_rate: 2,
            status: "active"
          )
          transaction.save(validate: false)

          delete_transaction = FactoryBot.build(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190201",
            for_normal_rate: 20,
            for_government_rate: 20,
            for_sub_dealer_rate: 20,
            for_individual_rate: 20,
            status: "retired",
          )
    
          delete_transaction.save(validate: false)
        end

        it 'get latest_for_government_rate from latest history correctly' do
          latest_for_government_rate = dealer.latest_for_government_rate("20190214")
          expect(latest_for_government_rate).to eq(20)
        end

        it 'should not get latest_for_government_rate from latest history scheduled' do
          FactoryBot.create(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190301",
            for_normal_rate: 30,
            for_government_rate: 20,
            for_sub_dealer_rate: 20,
            for_individual_rate: 20,
          )

          latest_for_government_rate = dealer.latest_for_government_rate("20190301")
          expect(latest_for_government_rate).to eq(2)
        end
      end
    end
  end

  describe '#latest_for_sub_dealer_rate' do
    describe 'no history' do
      let(:dealer) { FactoryBot.create(:dealer) }
      it 'get latest_for_sub_dealer_rate correctly' do
        latest_for_sub_dealer_rate = dealer.latest_for_sub_dealer_rate
        expect(latest_for_sub_dealer_rate).to eq(dealer.for_sub_dealer_rate)
      end
    end

    describe 'with history' do
      let(:dealer) { FactoryBot.create(:dealer) }
      describe 'active history' do
        before do
          FactoryBot.create(:system_setting)
          FactoryBot.create(:business_day, business_ymd: '20190215')
          transaction = FactoryBot.build(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190215",
            for_normal_rate: 30,
            for_government_rate: 20,
            for_sub_dealer_rate: 20,
            for_individual_rate: 20,
            status: "active"
          )
          transaction.save(validate: false)
        end

        it 'get latest_for_sub_dealer_rate from latest history correctly' do
          latest_for_sub_dealer_rate = dealer.latest_for_sub_dealer_rate
          expect(latest_for_sub_dealer_rate).to eq(20)
        end
      end

      describe 'input_ymd history' do
        before do
          FactoryBot.create(:system_setting)
          FactoryBot.create(:business_day, business_ymd: '20190215')
          transaction = FactoryBot.build(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190215",
            for_normal_rate: 3,
            for_government_rate: 2,
            for_sub_dealer_rate: 2,
            for_individual_rate: 2,
            status: "active"
          )
          transaction.save(validate: false)

          delete_transaction = FactoryBot.build(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190201",
            for_normal_rate: 20,
            for_government_rate: 20,
            for_sub_dealer_rate: 20,
            for_individual_rate: 20,
            status: "retired",
          )
    
          delete_transaction.save(validate: false)
        end

        it 'get latest_for_sub_dealer_rate from latest history correctly' do
          latest_for_sub_dealer_rate = dealer.latest_for_sub_dealer_rate("20190214")
          expect(latest_for_sub_dealer_rate).to eq(20)
        end

        it 'should not get latest_for_sub_dealer_rate from latest history scheduled' do
          FactoryBot.create(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190301",
            for_normal_rate: 30,
            for_government_rate: 20,
            for_sub_dealer_rate: 20,
            for_individual_rate: 20,
          )

          latest_for_sub_dealer_rate = dealer.latest_for_sub_dealer_rate("20190301")
          expect(latest_for_sub_dealer_rate).to eq(2)
        end
      end
    end
  end

  describe '#latest_for_individual_rate' do
    describe 'no history' do
      let(:dealer) { FactoryBot.create(:dealer) }
      it 'get latest_for_individual_rate correctly' do
        latest_for_individual_rate = dealer.latest_for_individual_rate
        expect(latest_for_individual_rate).to eq(dealer.for_individual_rate)
      end
    end

    describe 'with history' do
      let(:dealer) { FactoryBot.create(:dealer) }
      describe 'active history' do
        before do
          FactoryBot.create(:system_setting)
          FactoryBot.create(:business_day, business_ymd: '20190215')
          transaction = FactoryBot.build(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190215",
            for_normal_rate: 30,
            for_government_rate: 20,
            for_sub_dealer_rate: 20,
            for_individual_rate: 20,
            status: "active"
          )
          transaction.save(validate: false)
        end

        it 'get latest_for_individual_rate from latest history correctly' do
          latest_for_individual_rate = dealer.latest_for_individual_rate
          expect(latest_for_individual_rate).to eq(20)
        end
      end

      describe 'input_ymd history' do
        before do
          FactoryBot.create(:system_setting)
          FactoryBot.create(:business_day, business_ymd: '20190215')
          transaction = FactoryBot.build(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190215",
            for_normal_rate: 3,
            for_government_rate: 2,
            for_sub_dealer_rate: 2,
            for_individual_rate: 2,
            status: "active"
          )
          transaction.save(validate: false)

          delete_transaction = FactoryBot.build(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190201",
            for_normal_rate: 20,
            for_government_rate: 20,
            for_sub_dealer_rate: 20,
            for_individual_rate: 20,
            status: "retired",
          )
    
          delete_transaction.save(validate: false)
        end

        it 'get latest_for_individual_rate from latest history correctly' do
          latest_for_individual_rate = dealer.latest_for_individual_rate("20190214")
          expect(latest_for_individual_rate).to eq(20)
        end

        it 'should not get latest_for_individual_rate from latest history scheduled' do
          FactoryBot.create(:transaction_fee_history,
            dealer: dealer,
            apply_ymd: "20190301",
            for_normal_rate: 30,
            for_government_rate: 20,
            for_sub_dealer_rate: 20,
            for_individual_rate: 20,
          )

          latest_for_individual_rate = dealer.latest_for_individual_rate("20190301")
          expect(latest_for_individual_rate).to eq(2)
        end
      end
    end
  end

  describe '#create_transaction_fee_history' do
    let(:dealer) { FactoryBot.create(:dealer) }
    before do
      FactoryBot.create(:system_setting)
      FactoryBot.create(:business_day, business_ymd: '20190215')
    end

    it 'should create transaction_fee_history correctly' do
      dealer.create_transaction_fee_history
      transaction_fee_history = TransactionFeeHistory.active_transaction.find_by(dealer_id: dealer.id)
      expect(transaction_fee_history).to be_present
      expect(transaction_fee_history.apply_ymd).to eq('20190215')
      expect(transaction_fee_history.for_normal_rate).to eq(dealer.for_normal_rate)
      expect(transaction_fee_history.for_government_rate).to eq(dealer.for_government_rate)
      expect(transaction_fee_history.for_sub_dealer_rate).to eq(dealer.for_sub_dealer_rate)
      expect(transaction_fee_history.for_individual_rate).to eq(dealer.for_individual_rate)
      expect(transaction_fee_history.reason).to eq('new transaction')
      expect(transaction_fee_history.status).to eq('active')
    end
  end
end
