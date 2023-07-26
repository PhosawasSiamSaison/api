# == Schema Information
#
# Table name: orders
#
#  id                             :bigint(8)        not null, primary key
#  order_number                   :string(255)      not null
#  contractor_id                  :integer          not null
#  dealer_id                      :integer
#  second_dealer_id               :bigint(8)
#  site_id                        :integer
#  project_phase_site_id          :bigint(8)
#  order_type                     :string(30)
#  product_id                     :integer
#  bill_date                      :string(15)       default(""), not null
#  rescheduled_new_order_id       :integer
#  rescheduled_fee_order_id       :integer
#  rescheduled_user_id            :integer
#  rescheduled_at                 :datetime
#  fee_order                      :boolean          default(FALSE)
#  installment_count              :integer          not null
#  purchase_ymd                   :string(8)        not null
#  purchase_amount                :decimal(10, 2)   not null
#  amount_without_tax             :decimal(10, 2)
#  second_dealer_amount           :decimal(10, 2)
#  paid_up_ymd                    :string(8)
#  input_ymd                      :string(8)
#  input_ymd_updated_at           :datetime
#  change_product_status          :integer          default("unapply"), not null
#  is_applying_change_product     :boolean          default(FALSE), not null
#  applied_change_product_id      :integer
#  change_product_memo            :string(200)
#  change_product_before_due_ymd  :string(8)
#  change_product_applied_at      :datetime
#  product_changed_at             :datetime
#  product_changed_user_id        :integer
#  change_product_applied_user_id :integer
#  change_product_apply_id        :integer
#  region                         :string(50)
#  order_user_id                  :integer
#  canceled_at                    :datetime
#  canceled_user_id               :integer
#  rudy_purchase_ymd              :string(8)
#  uniq_check_flg                 :boolean          default(TRUE)
#  deleted                        :integer          default(0), not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  operation_updated_at           :datetime
#  lock_version                   :integer          default(0)
#

require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:product1) { Product.find_by(product_key: 1) }
  let(:product2) { Product.find_by(product_key: 2) }
  let(:product3) { Product.find_by(product_key: 3) }
  let(:product4) { Product.find_by(product_key: 4) }

  before do
    FactoryBot.create(:system_setting)
  end

  describe 'calc_remainings' do
    let(:contractor) { FactoryBot.create(:contractor) }

    before do
      order1 = FactoryBot.create(:order, :inputed_date, contractor: contractor)
      order2 = FactoryBot.create(:order, :inputed_date)

      FactoryBot.create(:installment, order: order1, principal: 1, interest: 2)
      FactoryBot.create(:installment, order: order2, principal: 10, interest: 20)
    end

    it '対象のオーダーのみの値が取得できること' do
      remainings = contractor.orders.calc_remainings('20200101')
      expect(remainings[:principal]).to eq 1
      expect(remainings[:interest]).to eq 2
      expect(remainings[:late_charge]).to be > 0
      expect(remainings[:interest_and_late_charge]).to be > 1
      expect(remainings[:total_balance]).to be > 3
    end
  end

  describe '#search' do
    let(:default_params) {
      {
        search: {
          order_number: '',
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

    describe '正常値のチェック' do
      before do
        FactoryBot.create(:order)
      end

      it 'パラメーターが空欄で取得できること' do
        orders, total_count = Order.search(default_params)

        expect(orders.count).to eq 1
        expect(total_count).to eq 1
      end
    end
    
    describe "ページング" do
      before do
        FactoryBot.create(:order, purchase_ymd: '20190101')
        FactoryBot.create(:order, purchase_ymd: '20190102')
      end

      it "ページ１が正しく値が取得できること" do
        params = default_params.dup
        # page: 1
        params[:page] = 1
        params[:per_page] = 1

        orders, total_count = Order.search(params)

        expect(orders.count).to eq 1
        expect(total_count).to eq 2
        expect(orders.first.purchase_ymd).to eq '20190102'
      end

      it "ページ２が正しく値が取得できること" do
        params = default_params.dup
        # page: 2
        params[:page] = 2
        params[:per_page] = 1

        orders, total_count = Order.search(params)

        expect(orders.count).to eq 1
        expect(total_count).to eq 2
        expect(orders.first.purchase_ymd).to eq '20190101'
      end
    end

    describe "Order Number(order_number)" do
      before do
        FactoryBot.create(:order, order_number: "R000000001")
        FactoryBot.create(:order, order_number: "R000000002")
      end

      it '取得できること' do
        params = default_params.dup
        params[:search][:order_number] = "R000000001"

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 1
        expect(total_count).to eq 1
      end

      it '取得できないこと' do
        params = default_params.dup
        params[:search][:order_number] = "R000000003"

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 0
        expect(total_count).to eq 0
      end
    end

    describe "Dealer" do
      let(:dealer) { FactoryBot.create(:dealer) }

      before do
        FactoryBot.create(:order, dealer: dealer)
      end

      it '取得できること' do
        params = default_params.dup
        params[:search][:dealer_id] = dealer.id

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 1
        expect(total_count).to eq 1
        expect(orders.first.dealer).to eq dealer
      end

      it 'nilで取得できること' do
        params = default_params.dup
        params[:search][:dealer_id] = nil

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 1
        expect(total_count).to eq 1
      end
    end

    describe "TAX ID(tax_id)" do
      let(:contractor) { FactoryBot.create(:contractor) }
      before do
        FactoryBot.create(:order, contractor: contractor)
      end

      it '取得できること' do
        params = default_params.dup
        params[:search][:tax_id] = contractor.tax_id

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 1
        expect(total_count).to eq 1
      end

      it '取得できないこと' do
        params = default_params.dup
        params[:search][:tax_id] = "0000000000000"

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 0
        expect(total_count).to eq 0
      end
    end

    describe "Purchase Date" do
      before do
        FactoryBot.create(:order, purchase_ymd: '20190102')
      end

      it '取得できること' do
        params = default_params.dup
        params[:search][:purchase][:from_ymd] = "20190102"
        params[:search][:purchase][:to_ymd] = "20190102"

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 1
        expect(total_count).to eq 1
      end

      it '取得できること(空欄)' do
        params = default_params.dup
        params[:search][:purchase][:from_ymd] = ""
        params[:search][:purchase][:to_ymd] = nil

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 1
        expect(total_count).to eq 1
      end

      it '取得できないこと(from_ymdの範囲外)' do
        params = default_params.dup
        params[:search][:purchase][:from_ymd] = "20190103"
        params[:search][:purchase][:to_ymd] = ""

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 0
        expect(total_count).to eq 0
      end

      it '取得できないこと(to_ymdの範囲外)' do
        params = default_params.dup
        params[:search][:purchase][:from_ymd] = ""
        params[:search][:purchase][:to_ymd] = "20190101"

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 0
        expect(total_count).to eq 0
      end
    end

    describe "Company Name" do
      let(:contractor) { FactoryBot.create(:contractor, th_company_name: 'th', en_company_name: 'en') }
      before do
        FactoryBot.create(:order, contractor: contractor)
      end

      it '前方一致で取得できること(TH)' do
        params = default_params.dup
        params[:search][:company_name] = 't'

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 1
      end

      it '前方一致で取得できること(EN)' do
        params = default_params.dup
        params[:search][:company_name] = 'e'

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 1
      end

      it '不一致で取得できること' do
        params = default_params.dup
        params[:search][:company_name] = 'eh'

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 0
      end
    end

    describe 'Include No Input Date' do
      before do
        FactoryBot.create(:order, input_ymd: nil)
        FactoryBot.create(:order, input_ymd: '20190101')
      end

      it 'input_ymd のないOrderが含まれないこと' do
        params = default_params.dup
        params[:search][:include_no_input_date] = false

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 1
      end

      it 'input_ymd のあるOrderが含まれること' do
        params = default_params.dup
        params[:search][:include_no_input_date] = true

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 2
      end
    end

    describe 'Include Paid Up' do
      before do
        FactoryBot.create(:order)
        FactoryBot.create(:order, paid_up_ymd: '20190101')
      end

      it 'paid upが含まれないこと' do
        params = default_params.dup
        params[:search][:include_paid_up] = false

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 1
      end

      it 'paid upが含まれること' do
        params = default_params.dup
        params[:search][:include_paid_up] = true

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 2
      end
    end

    describe 'Include Canceled' do
      before do
        FactoryBot.create(:order)
        FactoryBot.create(:order, canceled_at: Time.now)
      end

      it 'キャンセルが含まれないこと' do
        params = default_params.dup
        params[:search][:include_canceled] = false

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 1
      end

      it 'キャンセルが含まれること' do
        params = default_params.dup
        params[:search][:include_canceled] = true

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 2
      end
    end

    describe "Site Code" do
      let(:contractor) { FactoryBot.create(:contractor) }
      before do
        site = FactoryBot.create(:site, contractor: contractor, site_code: "1234")
        FactoryBot.create(:order, contractor: contractor, site: site)
      end

      it '取得できること' do
        params = default_params.dup
        params[:search][:site_code] = "1234"

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 1
        expect(total_count).to eq 1
      end

      it '取得できないこと' do
        params = default_params.dup
        params[:search][:site_code] = "1111"

        orders, total_count = Order.search(params)
        expect(orders.count).to eq 0
        expect(total_count).to eq 0
      end
    end
  end

  describe '#update_due_ymd' do
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Foo') }
    let(:contractor) { FactoryBot.create(:contractor, main_dealer: dealer) }
    let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }

    describe '全てのPaymentを削除、新規作成' do
      let(:order) {
        FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product2, installment_count: product2.number_of_installments,
          purchase_ymd: '20190115', purchase_amount: 3000.01, order_user: contractor_user)
      }

      before do
        FactoryBot.create(:business_day, business_ymd: '20190115')

        payment1 = Payment.create!(contractor: contractor, due_ymd: '20190215', total_amount: 1000.01, status: 'next_due')
        payment2 = Payment.create!(contractor: contractor, due_ymd: '20190315', total_amount: 1000.00, status: 'not_due_yet')
        payment3 = Payment.create!(contractor: contractor, due_ymd: '20190415', total_amount: 1000.00, status: 'not_due_yet')

        FactoryBot.create(:installment, order: order, payment: payment1,
          installment_number: 1, due_ymd: '20190215', principal: 900.01, interest: 100)
        FactoryBot.create(:installment, order: order, payment: payment2,
          installment_number: 2, due_ymd: '20190315', principal: 900, interest: 100)
        FactoryBot.create(:installment, order: order, payment: payment3,
          installment_number: 3, due_ymd: '20190415', principal: 900, interest: 100)
      end

      it 'installmentとpaymentのデータが正しく更新されること' do
        order = Order.find_by(order_number: '1')

        expect(order.present?).to eq true
        expect(order.installments.count).to eq 3

        installment1 = order.installments.find_by(installment_number: 1)
        installment2 = order.installments.find_by(installment_number: 2)
        installment3 = order.installments.find_by(installment_number: 3)

        # 作成したinstallmentの確認
        expect(installment1.due_ymd).to eq '20190215'
        expect(installment2.due_ymd).to eq '20190315'
        expect(installment3.due_ymd).to eq '20190415'

        payment1 = installment1.payment
        payment2 = installment2.payment
        payment3 = installment3.payment

        # 作成したpaymentの確認
        expect(payment1.due_ymd).to eq '20190215'
        expect(payment2.due_ymd).to eq '20190315'
        expect(payment3.due_ymd).to eq '20190415'

        # 約定日の更新メソッドを実行
        order.update_due_ymd

        # installmentを最新へ
        installment1.reload
        installment2.reload
        installment3.reload

        # installment の約定日が月末に更新されること
        expect(installment1.due_ymd).to eq '20190228'
        expect(installment2.due_ymd).to eq '20190331'
        expect(installment3.due_ymd).to eq '20190430'

        # payment が全て消えていること
        expect(Payment.find_by(id: payment1.id).present?).to eq false
        expect(Payment.find_by(id: payment2.id).present?).to eq false
        expect(Payment.find_by(id: payment3.id).present?).to eq false

        # 新しい payment の約定日が月末に更新されること
        expect(installment1.payment.due_ymd).to eq '20190228'
        expect(installment2.payment.due_ymd).to eq '20190331'
        expect(installment3.payment.due_ymd).to eq '20190430'

        # 新しい payment の total_amount が更新されていること
        expect(installment1.payment.total_amount).to eq 1000.01
        expect(installment2.payment.total_amount).to eq 1000.0
        expect(installment2.payment.total_amount).to eq 1000.0
      end
    end

    describe '既存のPaymentへ更新' do
      let(:order1) {
        # due date: 2/15, 3/15, 4/15 確定
        FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product2, installment_count: product2.number_of_installments,
          purchase_ymd: '20190101', purchase_amount: 330, order_user: contractor_user,
          input_ymd: '20190101')
      }
      let(:order2) {
        # due date: 2/28 未確定
        FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
          product: product1, installment_count: product1.number_of_installments,
          purchase_ymd: '20190116', purchase_amount: 330, order_user: contractor_user)
      }

      before do
        FactoryBot.create(:business_day, business_ymd: '20190131')

        payment215 = Payment.create!(contractor: contractor, due_ymd: '20190215', total_amount: 110.0, status: 'next_due')
        payment315 = Payment.create!(contractor: contractor, due_ymd: '20190315', total_amount: 110.0, status: 'not_due_yet')
        payment415 = Payment.create!(contractor: contractor, due_ymd: '20190415', total_amount: 110.0, status: 'not_due_yet')

        payment228 = Payment.create!(contractor: contractor, due_ymd: '20190228', total_amount: 110.0, status: 'not_due_yet')
        
        # Oder1 Installments
        FactoryBot.create(:installment, order: order1, payment: payment215,
          installment_number: 1, due_ymd: '20190215', principal: 100, interest: 10)
        FactoryBot.create(:installment, order: order1, payment: payment315,
          installment_number: 2, due_ymd: '20190315', principal: 100, interest: 10)
        FactoryBot.create(:installment, order: order1, payment: payment415,
          installment_number: 3, due_ymd: '20190415', principal: 100, interest: 10)

        # Oder2 Installments
        FactoryBot.create(:installment, order: order2, payment: payment228,
          installment_number: 1, due_ymd: '20190228', principal: 100, interest: 10)
      end

      it 'installmentとpaymentのデータが正しく更新されること' do
        # 約定日の更新メソッドを実行
        order2.update_due_ymd

        installment1 = order2.installments.find_by(installment_number: 1)

        # installment の約定日が更新されること
        expect(installment1.due_ymd).to eq '20190315'

        # payment 2/28 が消えていること
        expect(Payment.find_by(due_ymd: '20190228').present?).to eq false
        # payment 5/15 が作成されていること
        #expect(Payment.find_by(due_ymd: '20190515').present?).to eq true
        #expect(Payment.find_by(due_ymd: '20190515').total_amount).to eq 110

        # installment が移動した payment の total_amount が減っていること
        #expect(Payment.find_by(due_ymd: '20190215').total_amount).to eq 1000.0
        #expect(Payment.find_by(due_ymd: '20190315').total_amount).to eq 1000.0

        # 新しい payment の total_amount が更新されていること
        expect(installment1.payment.total_amount.to_f).to eq 220
      end
    end

    describe '既存のPaymentから更新' do
      let(:order1) {
        # due date: 2/15, 3/15, 4/15 確定
        FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product2, installment_count: product2.number_of_installments,
          purchase_ymd: '20190101', purchase_amount: 330, order_user: contractor_user,
          input_ymd: '20190101')
      }
      let(:order2) {
        # due date: 3/15 未確定
        FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
          product: product1, installment_count: product1.number_of_installments,
          purchase_ymd: '20190201', purchase_amount: 330, order_user: contractor_user)
      }

      before do
        FactoryBot.create(:business_day, business_ymd: '20190215')

        payment215 = Payment.create!(contractor: contractor, due_ymd: '20190215', total_amount: 110.0, status: 'next_due')
        payment315 = Payment.create!(contractor: contractor, due_ymd: '20190315', total_amount: 220.0, status: 'not_due_yet')
        payment415 = Payment.create!(contractor: contractor, due_ymd: '20190415', total_amount: 110.0, status: 'not_due_yet')

        # Oder1 Installments
        FactoryBot.create(:installment, order: order1, payment: payment215,
          installment_number: 1, due_ymd: '20190215', principal: 100, interest: 10)
        FactoryBot.create(:installment, order: order1, payment: payment315,
          installment_number: 2, due_ymd: '20190315', principal: 100, interest: 10)
        FactoryBot.create(:installment, order: order1, payment: payment415,
          installment_number: 3, due_ymd: '20190415', principal: 100, interest: 10)

        # Oder2 Installments
        FactoryBot.create(:installment, order: order2, payment: payment315,
          installment_number: 1, due_ymd: '20190315', principal: 100, interest: 10)
      end

      it 'installmentとpaymentのデータが正しく更新されること' do
        # 約定日の更新メソッドを実行
        order2.update_due_ymd

        installment1 = order2.installments.find_by(installment_number: 1)

        # installment の約定日が更新されること
        expect(installment1.due_ymd).to eq '20190331'

        # payment 3/31 が作成されていること
        expect(Payment.find_by(due_ymd: '20190331').present?).to eq true
        expect(Payment.find_by(due_ymd: '20190331').total_amount).to eq 110

        # installment が移動した payment の total_amount が減っていること
        expect(Payment.find_by(due_ymd: '20190315').total_amount).to eq 110
      end
    end
  end

  describe '#purchase_amount_without_vat' do
    context 'amount_without_tax なし' do
      let(:order) { FactoryBot.create(:order, purchase_amount: 100, amount_without_tax: nil )}

      it 'purchase_amountから値が算出されること' do
        expect(order.purchase_amount_without_vat).to be < 100
      end
    end

    context 'amount_without_tax あり' do
      let(:order) { FactoryBot.create(:order, purchase_amount: 100, amount_without_tax: 200 )}

      it 'amount_without_taxから値が取得されること' do
        expect(order.purchase_amount_without_vat).to eq 200
      end
    end
  end


  xdescribe '#can_get_apply_change_product_schedule?' do
    let(:contractor) { FactoryBot.create(:contractor) }

    context '3回払い' do
      let(:order) { FactoryBot.create(:order, :inputed_date, contractor: contractor,
        product: product2) }

      before do
        FactoryBot.create(:business_day, business_ymd: '20190212')
      end

      it 'falseになること' do
        expect(order.can_get_apply_change_product_schedule?).to eq false
      end
    end

    context '1回払い' do
      let(:order) { FactoryBot.create(:order, :inputed_date, contractor: contractor,
        product: product1) }

      before do
        FactoryBot.create(:business_day, business_ymd: '20190212')
      end

      it 'true' do
        expect(order.can_get_apply_change_product_schedule?).to eq true
      end
    end

    context 'rejected' do
      let(:order) {
        FactoryBot.create(:order, :inputed_date, contractor: contractor, product: product1,
          change_product_status: :rejected)
      }

      before do
        FactoryBot.create(:business_day, business_ymd: '20190212')
      end

      it 'falseになること' do
        expect(order.can_get_apply_change_product_schedule?).to eq false
      end
    end

    context 'unapply' do
      let(:order) {
        FactoryBot.create(:order, :inputed_date, contractor: contractor, product: product1,
          change_product_status: :unapply)
      }

      before do
        FactoryBot.create(:business_day, business_ymd: '20190212')
      end

      it 'true' do
        expect(order.can_get_apply_change_product_schedule?).to eq true
      end
    end
  end


  describe '#over_apply_change_product_limit_date?' do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:order) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20190101') }

    before do
      FactoryBot.create(:business_day, business_ymd: business_ymd)

      payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')
      FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
        due_ymd: '20190215', principal: 3000, interest: 0)
    end

    context '約定日の３日前' do
      let(:business_ymd) { '20190212' }

      it '申請できないこと' do
        expect(order.over_apply_change_product_limit_date?).to eq false
      end
    end

    context '約定日の2日前' do
      let(:business_ymd) { '20190213' }

      it '申請できること' do
        expect(order.over_apply_change_product_limit_date?).to eq true
      end
    end
  end

  describe '#apply_change_product_limit_date' do
    let(:site) { FactoryBot.create(:site) }
    let(:cbm_dealer) { FactoryBot.create(:cbm_dealer) }
    let(:order) { FactoryBot.create(:order, dealer: cbm_dealer) }

    before do
      FactoryBot.create(:business_day)
    end

    context 'auto_approval: true' do
      before do
        cbm_dealer.dealer_type_setting.update!(switch_auto_approval: true)
      end

      it 'DueDateになること' do
        # CBMオーダー
        expect(order.apply_change_product_limit_date('20200615').strftime('%Y%m%d')).to eq '20200615'
      end
    end

    context 'auto_approval: false' do
      before do
        cbm_dealer.dealer_type_setting.update!(switch_auto_approval: false)
      end

      it '3営業日前になること' do
        # CBMオーダー
        expect(order.apply_change_product_limit_date('20200615').strftime('%Y%m%d')).to eq '20200610'
      end
    end
  end

  describe '#apply_change_product_errors' do
    let(:order) { FactoryBot.create(:order, :inputed_date) }

    before do
      FactoryBot.create(:business_day, business_ymd: '20190116')
    end

    context 'エラーなし' do
      before do
        FactoryBot.create(:installment, order: order, due_ymd: '20190215')
      end

      it 'からになること' do
        expect(order.apply_change_product_errors).to eq []
      end
    end

    context '期限エラー' do
      before do
        BusinessDay.first.update!(business_ymd: '20190213')
        FactoryBot.create(:installment, order: order, due_ymd: '20190215')
      end

      it '期限エラーメッセージが返ること' do
        expect(order.apply_change_product_errors).to eq [
          I18n.t("error_message.over_apply_change_product_limit_date")
        ]
      end
    end

    context '一部支払済エラー' do
      before do
        FactoryBot.create(:installment, order: order, due_ymd: '20190215', paid_principal: 1)
      end

      it '支払済エラーメッセージが返ること' do
        expect(order.apply_change_product_errors).to eq [
          I18n.t("error_message.some_amount_has_already_been_paid")
        ]
      end
    end

    context '両方' do
      before do
        BusinessDay.first.update!(business_ymd: '20190213')
        FactoryBot.create(:installment, order: order, due_ymd: '20190215', paid_principal: 1)
      end

      it '期限エラーと一部支払済エラーのメッセージが返ること' do
        expect(order.apply_change_product_errors).to eq [
          I18n.t("error_message.over_apply_change_product_limit_date"),
          I18n.t("error_message.some_amount_has_already_been_paid")
        ]
      end
    end
  end

  describe '#can_apply_change_product?' do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:order) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20190101') }

    describe '期日' do
      context '約定日の３日前' do
        before do
          FactoryBot.create(:business_day, business_ymd: '20190212')

          payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')
          FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
            due_ymd: '20190215', principal: 3000, interest: 0)
        end

        it 'trueになること' do
          expect(order.can_apply_change_product?).to eq true
        end
      end

      context '約定日の２日前' do
        before do
          FactoryBot.create(:business_day, business_ymd: '20190212')

          payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')
          FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
            due_ymd: '20190215', principal: 3000, interest: 0)
        end

        it 'trueになること' do
          expect(order.can_apply_change_product?).to eq true
        end
      end
    end

    context 'product2' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190201')

        payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')
        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)

        order.update!(product: product2)
      end

      it 'falseになること' do
        expect(order.can_apply_change_product?).to eq false
      end
    end

    context 'status: approval' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190201')

        payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')
        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)

        order.approval!
      end

      it 'falseになること' do
        expect(order.can_apply_change_product?).to eq false
      end
    end

    context '一部を支払済' do
    end
  end


  describe '#can_get_change_product_schedule?' do
    before do
      FactoryBot.create(:business_day, business_ymd: '20190212')
    end

    context '3回払い(未申請)' do
      let(:order) { FactoryBot.create(:order, product: product2, change_product_status: :unapply) }

      it 'falseになること' do
        expect(order.can_get_change_product_schedule?).to eq false
      end
    end

    context '3回払い(申請済)' do
      let(:order) { FactoryBot.create(:order, product: product2, change_product_status: :approval) }

      it 'true' do
        expect(order.can_get_change_product_schedule?).to eq true
      end
    end

    context 'canceled' do
      let(:order) {
        FactoryBot.create(:order, :canceled, product: product1, change_product_status: :unapply) }

      it 'falseになること' do
        expect(order.can_get_change_product_schedule?).to eq false
      end
    end

    context 'not input date' do
      let(:order) {
        FactoryBot.create(:order, input_ymd: nil, product: product1, change_product_status: :unapply) }

      it 'true' do
        expect(order.can_get_change_product_schedule?).to eq true
      end
    end

    context 'rescheduled new order' do
      let(:order) {
        FactoryBot.create(:order, dealer: nil, product: nil, rescheduled_at: Time.now) }

      it 'false' do
        expect(order.can_get_change_product_schedule?).to eq false
      end
    end
  end

  describe '#change_product_errors' do
    let(:order) { FactoryBot.create(:order, :inputed_date) }

    before do
      FactoryBot.create(:business_day, business_ymd: '20190215')
    end

    context 'エラーなし' do
      before do
        FactoryBot.create(:installment, order: order, due_ymd: '20190215')
      end

      it 'からになること' do
        expect(order.change_product_errors).to eq []
      end
    end

    context '期限エラー' do
      before do
        BusinessDay.first.update!(business_ymd: '20190216')
        FactoryBot.create(:installment, order: order, due_ymd: '20190215')
      end

      it '期限エラーメッセージが返らないこと' do
        expect(order.change_product_errors).to eq []
      end
    end

    context '一部支払済エラー' do
      before do
        FactoryBot.create(:installment, order: order, due_ymd: '20190215', paid_principal: 1)
      end

      it '支払済エラーメッセージが返ること' do
        expect(order.change_product_errors).to eq [
          I18n.t("error_message.some_amount_has_already_been_paid")
        ]
      end
    end

    context 'input date なし' do
      let(:order) { FactoryBot.create(:order, input_ymd: nil) }

      before do
        FactoryBot.create(:installment, order: order, due_ymd: '20190215')
      end

      it 'ino_input_dateエラーメッセージが返ること' do
        expect(order.change_product_errors).to eq [
          I18n.t("error_message.no_input_date")
        ]
      end
    end

    context '全て' do
      let(:order) { FactoryBot.create(:order, input_ymd: nil) }

      before do
        BusinessDay.first.update!(business_ymd: '20190216')
        FactoryBot.create(:installment, order: order, due_ymd: '20190215', paid_principal: 1)
      end

      it '一部支払済エラーのメッセージが返ること' do
        expect(order.change_product_errors).to eq [
          I18n.t("error_message.some_amount_has_already_been_paid"),
          I18n.t("error_message.no_input_date"),
        ]
      end
    end

    context '全て(変更後)' do
      let(:order) { FactoryBot.create(:order, input_ymd: nil, change_product_status: :approval) }

      before do
        BusinessDay.first.update!(business_ymd: '20190216')
        FactoryBot.create(:installment, order: order, due_ymd: '20190215', paid_principal: 1)
      end

      it 'approvalあとは、からになる事' do
        expect(order.change_product_errors).to eq []
      end
    end
  end

  describe '#can_change_product?' do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:order) { FactoryBot.create(:order, contractor: contractor, purchase_amount: 3000, input_ymd: '20190115') }

    context '正常値' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190101')

        payment = FactoryBot.create(:payment, :not_due_yet, contractor: contractor,
          due_ymd: '20190215', total_amount: 3000)
        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it 'trueになること' do
        expect(order.can_change_product?).to eq true
      end
    end

    context 'キャンセル' do
      let(:order) { FactoryBot.create(:order, :canceled, contractor: contractor) }

      before do
        FactoryBot.create(:business_day, business_ymd: '20190101')

        payment = FactoryBot.create(:payment, :not_due_yet, contractor: contractor,
          due_ymd: '20190215', total_amount: 3000)
        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it 'falseになること' do
        expect(order.can_change_product?).to eq false
      end
    end

    context '一部を支払い済み' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190215')

        payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215',
          total_amount: 3000, paid_total_amount: 100)
        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0, paid_principal: 100)
      end

      it 'falseになること' do
        expect(order.can_change_product?).to eq false
      end
    end

    context 'over_due' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190216')

        payment = FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20190215',
          total_amount: 3000)
        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it 'trueになること' do
        expect(order.can_change_product?).to eq true
      end
    end

    context 'can_change_product' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190201')

        payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')
        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it 'input_ymd未入力がfalseになること' do
        expect(order.can_change_product?).to eq true
        order.update!(input_ymd: nil)
        expect(order.can_change_product?).to eq false
      end
    end

    context 'リスケした新しいオーダー' do
      before do
        order.update!(rescheduled_at: Time.now)

        FactoryBot.create(:business_day, business_ymd: '20190101')

        payment = FactoryBot.create(:payment, :not_due_yet, contractor: contractor,
          due_ymd: '20190215', total_amount: 3000)
        FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
          due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it 'falseになること' do
        expect(order.can_change_product?).to eq false
      end
    end
  end

  describe '#can_gain_cashback?' do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:order) {
      FactoryBot.create(:order, contractor: contractor, product: product1, paid_up_ymd: '20200101')
    }

    before do
      FactoryBot.create(:installment, order: order, due_ymd: '20200101')
    end

    context '' do
      before do
        FactoryBot.create(:available_product, contractor: contractor, product: product1,
          category: :cashback, dealer_type: :cbm, available: true)
      end

      it 'trueになること' do
        expect(order.can_gain_cashback?).to eq true
      end

      context 'Product 4' do
        before do
          order.update!(product: product4)
        end

        it 'falseになること' do
          expect(order.can_gain_cashback?).to eq false
        end
      end
    end
  end

  describe 'product' do
    context '通常のオーダー' do
      context 'Productの設定あり' do
        let(:order) { FactoryBot.create(:order, product: product1)}

        it '正常にProductが取得できること' do
          expect(order.product.product_key).to eq 1
        end
      end

      context 'Productの設定なし' do
        let(:order) { FactoryBot.create(:order, product: nil) }

        it 'Productがnilで取得できること' do
          expect(order.product.nil?).to eq true
        end
      end
    end

    context 'Feeオーダー' do
      let(:order) { FactoryBot.create(:order, :fee_order, product: nil, installment_count: 2) }

      it 'Fee用のProductが取得できること' do
        expect(order.product).to eq nil
      end
    end
  end

  describe 'order_basis_data' do
    describe 'キャンセルかつInput Date なし' do
      before do
        order = FactoryBot.create(:order, :canceled)
        FactoryBot.create(:installment, :deleted, order: order)
      end

      it '対象にならないこと' do
        installments = Order.order_basis_data()

        expect(installments.count).to eq 0
      end
    end

    describe 'キャンセルかつInput Date あり' do
      before do
        order = FactoryBot.create(:order, :canceled, :inputed_date)
        FactoryBot.create(:installment, :deleted, order: order)
      end

      it '対象になること' do
        installments = Order.order_basis_data()

        expect(installments.count).to eq 1
      end
    end

    describe '通常オーダー、Input Date あり' do
      before do
        order = FactoryBot.create(:order, :inputed_date)
        FactoryBot.create(:installment, order: order)
      end

      it '対象になること' do
        installments = Order.order_basis_data()

        expect(installments.count).to eq 1
      end
    end

    describe '通常オーダー、Input Date なし' do
      before do
        order = FactoryBot.create(:order)
        FactoryBot.create(:installment, order: order)
      end

      it '対象にならない' do
        installments = Order.order_basis_data()

        expect(installments.count).to eq 0
      end
    end

    describe '商品変更したオーダー' do
      before do
        order = FactoryBot.create(:order, :inputed_date, :product_changed)
        FactoryBot.create(:installment, :deleted, order: order, principal: 300)
        FactoryBot.create(:installment, order: order, principal: 100, installment_number: 1)
        FactoryBot.create(:installment, order: order, principal: 100, installment_number: 2)
        FactoryBot.create(:installment, order: order, principal: 100, installment_number: 3)
      end

      it '古いinstallmentは対象にならないこと' do
        installments = Order.order_basis_data()

        expect(installments.count).to eq 3

        installment1 = installments.first
        installment2 = installments.second
        installment3 = installments.third

        expect(installment1.installment_number).to eq 1
        expect(installment2.installment_number).to eq 2
        expect(installment3.installment_number).to eq 3
      end
    end

    describe '商品変更してキャンセルしたオーダー' do
      before do
        order = FactoryBot.create(:order, :inputed_date, :product_changed, :canceled)
        FactoryBot.create(:installment, :deleted, order: order, principal: 300, installment_number: 1)
        FactoryBot.create(:installment, :deleted, order: order, principal: 100, installment_number: 1)
        FactoryBot.create(:installment, :deleted, order: order, principal: 100, installment_number: 2)
        FactoryBot.create(:installment, :deleted, order: order, principal: 100, installment_number: 3)
      end

      it '商品変更後のキャンセル分のみが取得されること' do
        installments = Order.order_basis_data()

        expect(installments.count).to eq 3

        installment1 = installments.first
        installment2 = installments.second
        installment3 = installments.third

        expect(installment1.installment_number).to eq 1
        expect(installment2.installment_number).to eq 2
        expect(installment3.installment_number).to eq 3
      end
    end

    describe '順番' do
      before do
        order1 = FactoryBot.create(:order, :inputed_date, purchase_ymd: '20200102')
        order2 = FactoryBot.create(:order, :inputed_date, purchase_ymd: '20200101')
        order3 = FactoryBot.create(:order, :inputed_date, purchase_ymd: '20200103')
        FactoryBot.create(:installment, order: order2)
        FactoryBot.create(:installment, order: order1)
        FactoryBot.create(:installment, order: order3)
      end

      it '購入日順になること' do
        installments = Order.order_basis_data()

        expect(installments.count).to eq 3

        installment1 = installments.first
        installment2 = installments.second
        installment3 = installments.third

        expect(installment1.order.purchase_ymd).to eq '20200103'
        expect(installment2.order.purchase_ymd).to eq '20200102'
        expect(installment3.order.purchase_ymd).to eq '20200101'
      end
    end
  end

  describe '一意制約チェック' do
    let(:dealer) { FactoryBot.create(:dealer) }
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:product) { Product.find_by(product_key: 1) }

    before do
      FactoryBot.create(:business_day)
      FactoryBot.create(:order, order_number: '1', dealer: dealer, deleted: true, uniq_check_flg: nil)
      FactoryBot.create(:order, order_number: '1', dealer: dealer, canceled_at: Time.now, uniq_check_flg: nil)
    end

    it 'uniq_check_flgがnilのオーダーとは重複チェックにかからないこと' do
      expect(Order.exclude_canceled.count).to eq 0

      order = Order.new(
        contractor: contractor,
        order_number: '1',
        dealer: dealer,
        product: product,
        installment_count: product.number_of_installments,
        purchase_ymd: BusinessDay.today_ymd,
        purchase_amount: 10,
      )

      expect(order.valid?).to eq true

      order.save
      expect(Order.exclude_canceled.count).to eq 1
    end
  end

  describe '#calc_purchase_amount' do
    it '値が正しいこと' do
      order = FactoryBot.create(:order, purchase_amount: 1000)
      expect(order.calc_purchase_amount).to eq 1000

      order.second_dealer = FactoryBot.create(:dealer)
      order.second_dealer_amount = 300

      order.is_second_dealer = true
      expect(order.calc_purchase_amount).to eq 300

      order.is_second_dealer = false
      expect(order.calc_purchase_amount).to eq 700
    end
  end

  describe '#purchase_amount_without_vat' do
    it '値が正しいこと' do
      order = FactoryBot.create(:order, purchase_amount: 1070)
      expect(order.purchase_amount_without_vat).to eq 1000

      order.second_dealer = FactoryBot.create(:dealer)
      order.second_dealer_amount = 321

      order.is_second_dealer = true
      expect(order.purchase_amount_without_vat).to eq 300

      order.is_second_dealer = false
      expect(order.purchase_amount_without_vat).to eq 700
    end
  end

  describe '#vat_amount' do
    it '値が正しいこと' do
      order = FactoryBot.create(:order, purchase_amount: 1070)
      expect(order.vat_amount).to eq 70

      order.second_dealer = FactoryBot.create(:dealer)
      order.second_dealer_amount = 321

      order.is_second_dealer = true
      expect(order.vat_amount).to eq 21

      order.is_second_dealer = false
      expect(order.vat_amount).to eq 49
    end
  end

  describe '#calc_cashback_amount' do
    let(:order) { FactoryBot.create(:order, purchase_amount: 9678.23 ) }

    context 'input_ymdが2021-12-31' do
      before do
        order.update!(input_ymd: '20211231')
      end

      it 'vat_amountが引かれて計算されること' do
        expect(order.calc_cashback_amount).to eq 45.22
      end
    end

    context 'input_ymdが2022-01-01' do
      before do
        order.update!(input_ymd: '20220101')
      end

      it 'vat_amountが含まれて計算されること' do
        expect(order.calc_cashback_amount).to eq 48.39
      end
    end

    context 'input_ymdが2022-01-02' do
      before do
        order.update!(input_ymd: '20220102')
      end

      it 'vat_amountが含まれて計算されること' do
        expect(order.calc_cashback_amount).to eq 48.39
      end
    end
  end

  describe '#transaction_fee' do
    # government or sub_dealer ではないContractorを作成(dealerのtracsaction_rateを2%で計算)
    let(:contractor) { FactoryBot.create(:contractor, tax_id: '2000000000000', contractor_type: :normal) }
    let(:order) { FactoryBot.create(:order, contractor: contractor, purchase_amount: 9678.23 ) }

    context 'input_ymdが2021-12-31' do
      before do
        order.update!(input_ymd: '20211231')
      end

      it 'vat_amountが引かれて計算されること' do
        expect(order.transaction_fee).to eq 180.9
      end
    end

    context 'input_ymdが2022-01-01' do
      before do
        order.update!(input_ymd: '20220101')
      end

      it 'vat_amountが含まれて計算されること' do
        expect(order.transaction_fee).to eq 193.56
      end
    end

    context 'input_ymdが2022-01-02' do
      before do
        order.update!(input_ymd: '20220102')
      end

      it 'vat_amountが含まれて計算されること' do
        expect(order.transaction_fee).to eq 193.56
      end
    end
  end
end
