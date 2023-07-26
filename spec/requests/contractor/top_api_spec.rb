require 'rails_helper'

RSpec.describe "Contractor::Top Api", type: :request do
  let(:dealer) { FactoryBot.create(:dealer) }
  let(:product1) { Product.find_by(product_key: 1) }
  let(:product2) { Product.find_by(product_key: 2) }
  let(:product3) { Product.find_by(product_key: 3) }
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:auth_token) { FactoryBot.create(:auth_token, :contractor) }
  let(:contractor_user) { auth_token.tokenable }
  let(:contractor) { contractor_user.contractor }
  let(:eligibility) { FactoryBot.create(:eligibility, contractor: contractor) }

  before do
    FactoryBot.create(:business_day)
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)

    FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility, limit_amount: 99999999999)
    FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer, limit_amount: 99999999999)
    FactoryBot.create(:terms_of_service_version, :cbm, contractor_user: contractor_user)
  end

  describe 'キャッシュバックの日付' do
    before do
      FactoryBot.create(:dealer)
      BusinessDay.first.update!(business_ymd: '20190101')
    end

    it '過去のキャッシュバックなし' do
      expect(contractor.cashback_amount).to eq 0
      expect(contractor.cashback_use_ymd).to eq nil

      # 注文1
      order_number = '1'
      purchase_ymd = '20190101'
      amount = 10000
      create_order(contractor_user, order_number, product1, dealer, purchase_ymd, amount)

      # 入力1
      input_ymd = '20190101'
      set_input_date(contractor, order_number, dealer, input_ymd)

      Batch::Daily.exec(to_ymd: '20190116')

      expect(contractor.cashback_use_ymd).to eq nil

      # 注文2
      order_number = '2'
      purchase_ymd = '20190116'
      amount = 50
      create_order(contractor_user, order_number, product1, dealer, purchase_ymd, amount)

      # 入力2
      input_ymd = '20190116'
      set_input_date(contractor, order_number, dealer, input_ymd)

      expect(contractor.cashback_use_ymd).to eq nil

      Batch::Daily.exec(to_ymd: '20190201')

      expect(contractor.cashback_use_ymd).to eq nil

      AppropriatePaymentToInstallments.new(contractor, '20190201', 10000, jv_user, 'test').call
      contractor.reload

      expect(contractor.cashback_amount).to eq 46.72
      expect(contractor.cashback_use_ymd).to eq '20190228'

      # 注文3
      order_number = '3'
      purchase_ymd = '20190201'
      amount = 3000
      create_order(contractor_user, order_number, product1, dealer, purchase_ymd, amount)

      # 入力3
      input_ymd = '20190201'
      set_input_date(contractor, order_number, dealer, input_ymd)

      Batch::Daily.exec(to_ymd: '20190301')

      expect(contractor.cashback_amount).to eq 46.72
      expect(contractor.cashback_use_ymd).to eq '20190228'

      AppropriatePaymentToInstallments.new(contractor, '20190301', 1, jv_user, 'test').call
      contractor.reload
      expect(Payment.find_by(due_ymd: '20190228').paid?).to eq false

      expect(contractor.cashback_amount).to eq 0
      expect(contractor.cashback_use_ymd).to eq nil

      AppropriatePaymentToInstallments.new(contractor, '20190301', 10, jv_user, 'test').call
      contractor.reload
      expect(Payment.find_by(due_ymd: '20190228').paid?).to eq true

      expect(contractor.cashback_amount).to eq 0
      expect(contractor.cashback_use_ymd).to eq nil
    end

    context '過去のキャッシュバックあり' do
      before do
        order = FactoryBot.create(:order, order_number: '0', contractor: contractor, dealer: dealer,
          product: product1, installment_count: 1, purchase_ymd: '20180101',
          input_ymd: '20180102', purchase_amount: 1000.0, order_user: contractor_user,
          paid_up_ymd: '20180215')

        payment = Payment.create!(contractor: contractor, due_ymd: '20180215',
          total_amount: 1000.0, status: 'paid', paid_up_ymd: '20180215')

        FactoryBot.create(:installment, order: order, payment: payment,
          installment_number: 1, due_ymd: '20180215', principal: 1000.0, interest: 0.0,
          paid_up_ymd: '20180215', paid_principal: 1000.0)

        FactoryBot.create(:cashback_history, :gain, :latest, order: order, cashback_amount: 100, total: 100)
      end

      it 'ポイントを残す' do
        expect(contractor.cashback_use_ymd).to eq nil

        # 注文1
        order_number = '1'
        purchase_ymd = '20190101'
        amount = 20000
        create_order(contractor_user, order_number, product1, dealer, purchase_ymd, amount)

        # 入力1
        input_ymd = '20190101'
        set_input_date(contractor, order_number, dealer, input_ymd)

        Batch::Daily.exec(to_ymd: '20190116')

        expect(contractor.cashback_use_ymd).to eq '20190215'

        Batch::Daily.exec(to_ymd: '20190117')

        # 注文2
        order_number = '2'
        purchase_ymd = '20190117'
        amount = 20
        create_order(contractor_user, order_number, product1, dealer, purchase_ymd, amount)
        # 入力2
        input_ymd = '20190117'
        set_input_date(contractor, order_number, dealer, input_ymd)

        # 注文3
        order_number = '3'
        purchase_ymd = '20190117'
        amount = 30
        create_order(contractor_user, order_number, product1, dealer, purchase_ymd, amount)
        # 入力3
        input_ymd = '20190117'
        set_input_date(contractor, order_number, dealer, input_ymd)

        expect(contractor.cashback_use_ymd).to eq '20190215'

        Batch::Daily.exec(to_ymd: '20190201')

        expect(contractor.cashback_use_ymd).to eq '20190215'

        expect(contractor.cashback_amount).to eq 100
        AppropriatePaymentToInstallments.new(contractor, '20190201', 19900, jv_user, 'test').call
        contractor.reload
        expect(Payment.find_by(due_ymd: '20190215').paid?).to eq true
        expect(contractor.cashback_amount).to eq 93.45

        expect(contractor.cashback_use_ymd).to eq '20190228'

        expect(Payment.find_by(due_ymd: '20190228').total_amount).to eq 50
        AppropriatePaymentToInstallments.new(contractor, '20190201', 0, jv_user, 'test').call
        contractor.reload

        expect(contractor.cashback_use_ymd).to eq nil
        expect(contractor.cashback_amount).to eq 43.68
      end

      it 'ポイントを使い切る' do
        expect(contractor.cashback_use_ymd).to eq nil

        # 注文1
        order_number = '1'
        purchase_ymd = '20190101'
        amount = 20000
        create_order(contractor_user, order_number, product1, dealer, purchase_ymd, amount)

        # 入力1
        input_ymd = '20190101'
        set_input_date(contractor, order_number, dealer, input_ymd)

        Batch::Daily.exec(to_ymd: '20190116')

        expect(contractor.cashback_use_ymd).to eq '20190215'

        Batch::Daily.exec(to_ymd: '20190117')

        # 注文2
        order_number = '2'
        purchase_ymd = '20190117'
        amount = 200
        create_order(contractor_user, order_number, product1, dealer, purchase_ymd, amount)
        # 入力2
        input_ymd = '20190117'
        set_input_date(contractor, order_number, dealer, input_ymd)

        # 注文3
        order_number = '3'
        purchase_ymd = '20190117'
        amount = 300
        create_order(contractor_user, order_number, product1, dealer, purchase_ymd, amount)
        # 入力3
        input_ymd = '20190117'
        set_input_date(contractor, order_number, dealer, input_ymd)

        expect(contractor.cashback_use_ymd).to eq '20190215'

        Batch::Daily.exec(to_ymd: '20190201')

        expect(contractor.cashback_use_ymd).to eq '20190215'

        expect(contractor.cashback_amount).to eq 100
        AppropriatePaymentToInstallments.new(contractor, '20190201', 19900, jv_user, 'test').call
        contractor.reload
        expect(Payment.find_by(due_ymd: '20190215').paid?).to eq true
        expect(contractor.cashback_amount).to eq 93.45

        expect(contractor.cashback_use_ymd).to eq '20190228'

        expect(Payment.find_by(due_ymd: '20190228').total_amount).to eq 500
        AppropriatePaymentToInstallments.new(contractor, '20190201', 100, jv_user, 'test').call
        contractor.reload

        expect(contractor.cashback_use_ymd).to eq nil
        expect(contractor.cashback_amount).to eq 0
      end
    end
  end
end
