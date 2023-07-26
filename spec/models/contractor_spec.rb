# frozen_string_literal: true
#
# == Schema Information
#
# Table name: contractors
#
#  id                                       :bigint(8)        not null, primary key
#  tax_id                                   :string(15)       not null
#  contractor_type                          :integer          default("normal"), not null
#  main_dealer_id                           :integer
#  use_only_credit_limit                    :boolean          default(FALSE), not null
#  application_type                         :integer          not null
#  approval_status                          :integer          not null
#  application_number                       :string(20)
#  registered_at                            :datetime
#  register_user_id                         :integer
#  enable_rudy_confirm_payment              :boolean          default(TRUE)
#  pool_amount                              :decimal(10, 2)   default(0.0), not null
#  delay_penalty_rate                       :integer          default(18), not null
#  is_switch_unavailable                    :boolean          default(FALSE), not null
#  status                                   :integer          default("active"), not null
#  exemption_late_charge_count              :integer          default(0), not null
#  project_exemption_late_charge_count      :integer          default(0), not null
#  check_payment                            :boolean          default(FALSE), not null
#  stop_payment_sms                         :boolean          default(FALSE), not null
#  notes                                    :text(65535)
#  notes_updated_at                         :datetime
#  notes_update_user_id                     :integer
#  doc_company_registration                 :boolean          default(FALSE), not null
#  doc_vat_registration                     :boolean          default(FALSE), not null
#  doc_owner_id_card                        :boolean          default(FALSE), not null
#  doc_authorized_user_id_card              :boolean          default(FALSE), not null
#  doc_bank_statement                       :boolean          default(FALSE), not null
#  doc_tax_report                           :boolean          default(FALSE), not null
#  th_company_name                          :string(100)
#  en_company_name                          :string(100)
#  address                                  :string(200)
#  phone_number                             :string(20)
#  registration_no                          :string(30)
#  establish_year                           :string(4)
#  establish_month                          :string(2)
#  employee_count                           :string(6)
#  capital_fund_mil                         :string(20)
#  shareholders_equity                      :decimal(20, 2)
#  recent_revenue                           :decimal(20, 2)
#  short_term_loan                          :decimal(20, 2)
#  long_term_loan                           :decimal(20, 2)
#  recent_profit                            :decimal(20, 2)
#  apply_from                               :string(255)
#  th_owner_name                            :string(40)
#  en_owner_name                            :string(40)
#  owner_address                            :string(200)
#  owner_sex                                :integer
#  owner_birth_ymd                          :string(8)
#  owner_personal_id                        :string(20)
#  owner_email                              :string(200)
#  owner_mobile_number                      :string(15)
#  owner_line_id                            :string(20)
#  authorized_person_same_as_owner          :boolean          default(FALSE), not null
#  authorized_person_name                   :string(40)
#  authorized_person_title_division         :string(40)
#  authorized_person_personal_id            :string(20)
#  authorized_person_email                  :string(200)
#  authorized_person_mobile_number          :string(15)
#  authorized_person_line_id                :string(20)
#  contact_person_same_as_owner             :boolean          default(FALSE), not null
#  contact_person_same_as_authorized_person :boolean          default(FALSE), not null
#  contact_person_name                      :string(40)
#  contact_person_title_division            :string(40)
#  contact_person_personal_id               :string(20)
#  contact_person_email                     :string(200)
#  contact_person_mobile_number             :string(15)
#  contact_person_line_id                   :string(20)
#  approved_at                              :datetime
#  approval_user_id                         :integer
#  update_user_id                           :integer
#  online_apply_token                       :string(30)
#  deleted                                  :integer          default(0), not null
#  rejected_at                              :datetime
#  reject_user_id                           :integer
#  created_at                               :datetime         not null
#  create_user_id                           :integer
#  updated_at                               :datetime         not null
#  operation_updated_at                     :datetime
#  qr_code_updated_at                       :datetime
#  lock_version                             :integer          default(0)
#

require 'rails_helper'

RSpec.describe Contractor, type: :model do
  describe 'validation' do
    let(:contractor) { FactoryBot.build(:contractor, tax_id: '1000000000000') }

    describe 'tax_id' do
      describe 'uniqueness' do
        before do
          FactoryBot.create(:contractor, tax_id: '2000000000000')
        end

        it 'エラーにならないこと' do
          expect(contractor.valid?).to eq true
        end

        context '既存のContractorあり' do
          before do
            FactoryBot.create(:contractor, tax_id: '1000000000000')
          end

          it '重複エラーになること' do
            expect(contractor.invalid?).to eq true
            expect(contractor.errors.messages[:tax_id]).to eq ["has already been taken"]
          end
        end

        context '既存の tax_id 重複 Contractorの更新' do
          before do
            # tax_id が重複するデータを作成（既存レコードを想定）
            contractor.tax_id = Contractor.first.tax_id
            contractor.save(validate: false)
          end

          it 'tax_idを変更しない場合はエラーにならないこと' do
            expect(contractor.valid?).to eq true
          end
        end
      end
    end
  end

  describe '#search_processing' do
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Foo') }

    let(:default_params) {
      {
        search:   {
          dealer_name:  "",
          tax_id:       "",
          company_name: ""
        },
        page:     1,
        per_page: 20
      }
    }

    before do
      FactoryBot.create(:contractor,
                        tax_id: '0000000000111',
                        main_dealer:        dealer,
                        approval_status:    "processing")
    end

    it 'パラメーターが空欄で取得できること' do
      orders, total_count = Contractor.search_processing(default_params)

      expect(orders.count).to eq 1
      expect(total_count).to eq 1
    end

    describe "ページング" do
      before do
        FactoryBot.create(:contractor,
                          main_dealer:      dealer,
                          tax_id:          '0000000000222',
                          approval_status: "rejected")
      end

      it "ページ１が正しく値が取得できること" do
        params = default_params.dup
        # page: 1
        params[:page]     = 1
        params[:per_page] = 1

        contractors, total_count = Contractor.search_processing(params)

        expect(contractors.count).to eq 1
        expect(total_count).to eq 2
        expect(contractors.first.tax_id).to eq "0000000000222"
      end

      it "ページ２が正しく値が取得できること" do
        params = default_params.dup
        # page: 2
        params[:page]     = 2
        params[:per_page] = 1

        contractors, total_count = Contractor.search_processing(params)

        expect(contractors.count).to eq 1
        expect(total_count).to eq 2
        expect(contractors.first.tax_id).to eq "0000000000111"
      end
    end

    describe "TAX ID(tax_id)" do
      it '取得できること' do
        params                   = default_params.dup
        params[:search][:tax_id] = "0000000000111"

        contractors, total_count = Contractor.search_processing(params)
        expect(contractors.count).to eq 1
        expect(total_count).to eq 1
      end

      it '取得できないこと' do
        params                   = default_params.dup
        params[:search][:tax_id] = "333"

        contractors, total_count = Contractor.search_processing(params)
        expect(contractors.count).to eq 0
        expect(total_count).to eq 0
      end
    end

    describe "Company Name" do
      it '英語のCompany Nameで取得できること' do
        params                         = default_params.dup
        params[:search][:company_name] = "en"

        contractors, total_count = Contractor.search_processing(params)
        expect(contractors.count).to eq 1
        expect(total_count).to eq 1
      end

      it 'タイ語のCompany Nameで取得できること' do
        params                         = default_params.dup
        params[:search][:company_name] = "th"

        contractors, total_count = Contractor.search_processing(params)
        expect(contractors.count).to eq 1
        expect(total_count).to eq 1
      end

      it '取得できないこと' do
        params                         = default_params.dup
        params[:search][:company_name] = "foo"

        contractors, total_count = Contractor.search_processing(params)
        expect(contractors.count).to eq 0
        expect(total_count).to eq 0
      end
    end
  end

  describe '#search_qualified' do
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Foo') }

    let(:default_params) {
      {
        search:   {
          tax_id:       "",
          company_name: ""
        },
        page:     1,
        per_page: 20
      }
    }

    before do
      contractor1 = FactoryBot.create(:contractor,
                        main_dealer:        dealer,
                        tax_id:             "0000000000111",
                        application_number: "111",
                        approval_status:    "qualified")
      FactoryBot.create(:eligibility, contractor: contractor1)

      contractor2 = FactoryBot.create(:contractor,
                        main_dealer:        dealer,
                        tax_id:             "0000000000222",
                        application_number: "222",
                        approval_status:    "processing")
      FactoryBot.create(:eligibility, contractor: contractor2)

      contractor3 = FactoryBot.create(:contractor,
                        main_dealer:        dealer,
                        tax_id:             "0000000000333",
                        application_number: "333",
                        approval_status:    "pre_registration")
      FactoryBot.create(:eligibility, contractor: contractor3)
    end

    it 'パラメーターが空欄で取得できること' do
      orders, total_count = Contractor.search_qualified(default_params)

      expect(orders.count).to eq 1
      expect(total_count).to eq 1
    end

    describe "ページング" do
      before do
        contractor = FactoryBot.create(:contractor,
                          main_dealer:        dealer,
                          tax_id:             "0000000000444",
                          en_company_name:    "en_company2",
                          th_company_name:    "th_company2",
                          application_number: "444",
                          approval_status:    "qualified")
        FactoryBot.create(:eligibility, contractor: contractor)
      end

      it "ページ１が正しく値が取得できること" do
        params = default_params.dup
        # page: 1
        params[:page]     = 1
        params[:per_page] = 1

        contractors, total_count = Contractor.search_qualified(params)

        expect(contractors.count).to eq 1
        expect(total_count).to eq 2
        expect(contractors.first.tax_id).to eq "0000000000111"
      end

      it "ページ２が正しく値が取得できること" do
        params = default_params.dup
        # page: 2
        params[:page]     = 2
        params[:per_page] = 1

        contractors, total_count = Contractor.search_qualified(params)

        expect(contractors.count).to eq 1
        expect(total_count).to eq 2
        expect(contractors.first.tax_id).to eq "0000000000444"
      end
    end

    describe "TAX ID(tax_id)" do
      it '取得できること' do
        params                   = default_params.dup
        params[:search][:tax_id] = "0000000000111"

        contractors, total_count = Contractor.search_qualified(params)
        expect(contractors.count).to eq 1
        expect(total_count).to eq 1
      end

      it '取得できないこと' do
        params                   = default_params.dup
        params[:search][:tax_id] = "1111"

        contractors, total_count = Contractor.search_qualified(params)
        expect(contractors.count).to eq 0
        expect(total_count).to eq 0
      end
    end

    describe "Company Name" do
      it '英語のCompany Nameで取得できること' do
        params                         = default_params.dup
        params[:search][:company_name] = "en"

        contractors, total_count = Contractor.search_qualified(params)
        expect(contractors.count).to eq 1
        expect(total_count).to eq 1
      end

      it 'タイ語のCompany Nameで取得できること' do
        params                         = default_params.dup
        params[:search][:company_name] = "th"

        contractors, total_count = Contractor.search_qualified(params)
        expect(contractors.count).to eq 1
        expect(total_count).to eq 1
      end

      it '取得できないこと' do
        params                         = default_params.dup
        params[:search][:company_name] = "foo"

        contractors, total_count = Contractor.search_qualified(params)
        expect(contractors.count).to eq 0
        expect(total_count).to eq 0
      end
    end

    describe "Show Inactive" do
      before do
        contractor = FactoryBot.create(:contractor,
                          main_dealer:        dealer,
                          approval_status:    "qualified",
                          status:             "inactive")
        FactoryBot.create(:eligibility, contractor: contractor)
      end

      it 'インアクティブのみ取得できること' do
        params = default_params.dup

        params[:search][:show_inactive_only] = "true"
        contractors, total_count        = Contractor.search_qualified(params)
        expect(contractors.count).to eq 1
        expect(contractors.first.status).to eq "inactive"

        params[:search][:show_inactive_only] = true
        contractors, total_count        = Contractor.search_qualified(params)
        expect(contractors.count).to eq 1
        expect(contractors.first.status).to eq "inactive"
      end

      it 'アクティブも取得できること' do
        params = default_params.dup
        params[:search][:show_inactive_only] = "false"

        contractors, total_count = Contractor.search_qualified(params)
        expect(contractors.count).to eq 2

        params[:search][:show_inactive_only] = ""

        contractors, total_count = Contractor.search_qualified(params)
        expect(contractors.count).to eq 2
      end
    end
  end

  def validate_length_with_key_and_value(key, value)
    con = Contractor.new
    con.send("#{key}=", value)
    con.valid?
    con.errors
  end

  describe '#available_balance' do
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }
    let(:product) { Product.find_by(product_key: 1) }
    let(:order) {
      contractor.orders.create!(order_number: 1, dealer: contractor.main_dealer, product: product,
        installment_count: 1, purchase_ymd: '20190101', purchase_amount: 11000,
        order_user: contractor_user)
    }
    let(:payment) {
      Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 11000.0, status: 'next_due')
    }

    before do
      contractor.eligibilities.create!(limit_amount: 1000, class_type: 'b_class', comment: 'a',
        create_user: jv_user)
    end

    describe 'マイナス分' do
      before do
        order.installments.create!(payment: payment, installment_number: 1, due_ymd: '20190228',
          principal: 1001)
      end

      it '0.0になること' do
        expect(contractor.available_balance).to eq 0.0
      end
    end

    describe 'プラス分' do
      before do
        order.installments.create!(payment: payment, installment_number: 1, due_ymd: '20190228',
          principal: 999)
      end

      it '1.0になること' do
        expect(contractor.available_balance).to eq 1.0
      end
    end

    describe 'CPAC' do
      before do
        FactoryBot.create(:site, contractor: contractor, site_credit_limit: 100)
        FactoryBot.create(:site, :closed, contractor: contractor, site_credit_limit: 200)
      end

      it 'オープンなCPACのlimitだけが対象になっていること' do
        expect(contractor.available_balance).to eq 900
      end
    end

    describe 'dealer_type_available_balance' do
      let(:eligibility) { contractor.eligibilities.latest }

      before do
        FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility, limit_amount: 1000)

        cbm_order = FactoryBot.create(:order, :cbm, contractor: contractor)
        FactoryBot.create(:installment, order: cbm_order, principal: 300, paid_principal: 100)
      end

      it '値が正しいこと' do
        expect(contractor.dealer_type_available_balance(:cbm)).to eq 1000 - (300 - 100)
      end
    end

    describe 'dealer_available_balance' do
      let(:eligibility) { contractor.eligibilities.latest }
      let(:dealer) { FactoryBot.create(:cbm_dealer) }

      before do
        FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer, limit_amount: 900)

          cbm_order = FactoryBot.create(:order, contractor: contractor, dealer: dealer)
          FactoryBot.create(:installment, order: cbm_order, principal: 300, paid_principal: 100)
      end

      context '通常パターン' do
        before do
          FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility, limit_amount: 1000)
        end

        it '値が正しいこと' do
          expect(contractor.dealer_available_balance(dealer)).to eq 900 - (300 - 100)
        end
      end

      context 'Dealer Type Limitを超えるパターン' do
        before do
          FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility, limit_amount: 300)
        end

        it '値が正しいこと' do
          expect(contractor.dealer_available_balance(dealer)).to eq 300 - (300 - 100)
        end
      end
    end
  end

  describe '#remaining_principal' do
    let(:contractor) { FactoryBot.create(:contractor) }

    before do
      FactoryBot.create(:eligibility, :latest, contractor: contractor, limit_amount: 1000)
    end

    context 'site:300, open, site内は完済' do
      before do
        site = FactoryBot.create(:site, contractor: contractor, site_credit_limit: 300)
        order = FactoryBot.create(:order, contractor: contractor, site: site)
        FactoryBot.create(:installment, order: order, principal: 100, paid_principal: 100)
      end

      it 'siteのcredit_limit分が返済金額として取得されること' do
        expect(contractor.remaining_principal).to eq 300
      end
    end

    context 'site:300, open, site内は未完済' do
      before do
        site = FactoryBot.create(:site, contractor: contractor, site_credit_limit: 300)
        order = FactoryBot.create(:order, contractor: contractor, site: site)
        FactoryBot.create(:installment, order: order, principal: 100, paid_principal: 90)
      end

      it 'siteのcredit_limit分が返済金額として取得されること' do
        expect(contractor.remaining_principal).to eq 300
      end
    end

    context 'site:300, closed, site内は未完済' do
      before do
        site = FactoryBot.create(:site, :closed, contractor: contractor, site_credit_limit: 300)
        order = FactoryBot.create(:order, contractor: contractor, site: site)
        FactoryBot.create(:installment, order: order, principal: 100, paid_principal: 10)
      end

      it 'installmentの残り支払い元本が返済金額として取得されること' do
        expect(contractor.remaining_principal).to eq 90
      end
    end

    context '複数オーダー' do
      before do
        # 通常オーダー
        order1 = FactoryBot.create(:order, contractor: contractor)
        FactoryBot.create(:installment, order: order1, principal: 100, paid_principal: 10)

        # サイトオーダー(Open)
        site1 = FactoryBot.create(:site, contractor: contractor, site_credit_limit: 300)
        order2 = FactoryBot.create(:order, contractor: contractor, site: site1)
        FactoryBot.create(:installment, order: order2, principal: 100, paid_principal: 40)

        # サイトオーダー(Closed)
        site2 = FactoryBot.create(:site, :closed, contractor: contractor, site_credit_limit: 400)
        order3 = FactoryBot.create(:order, contractor: contractor, site: site2)
        FactoryBot.create(:installment, order: order3, principal: 200, paid_principal: 50)
      end

      it 'installmentの残り支払い元本が返済金額として取得されること' do
        expect(contractor.remaining_principal).to eq 90 + 300 + 150
      end
    end

    describe 'dealerTypeの指定' do
      let(:q_mix_dealer) { FactoryBot.create(:q_mix_dealer) }
      let(:cpac_dealer) { FactoryBot.create(:cpac_dealer) }

      before do
        ## CBMオーダー
        cbm_order = FactoryBot.create(:order, :cbm, contractor: contractor)
        FactoryBot.create(:installment, order: cbm_order, principal: 1000, paid_principal: 100)

        ## CPACオーダー
        # サイトオーダー(Open)
        open_site = FactoryBot.create(:site, contractor: contractor, dealer: cpac_dealer, site_credit_limit: 300)
        cpac_order1 = FactoryBot.create(:order, :cpac, contractor: contractor, site: open_site)
        FactoryBot.create(:installment, order: cpac_order1, principal: 100, paid_principal: 40)
        # サイトオーダー(Closed)
        closed_site2 = FactoryBot.create(:site, :closed, contractor: contractor, dealer: cpac_dealer, site_credit_limit: 400)
        cpac_order2 = FactoryBot.create(:order, :cpac, contractor: contractor, site: closed_site2)
        FactoryBot.create(:installment, order: cpac_order2, principal: 200, paid_principal: 50)
      end

      it '指定Dealerのオーダーのみが対象になること' do
        expect(contractor.dealer_type_remaining_principal(:cbm)).to eq 900
        expect(contractor.dealer_type_remaining_principal(:cpac)).to eq 300 + 150
      end
    end

    describe 'dealerの指定' do
      let(:cbm_dealer)   { Dealer.find_by(dealer_code: 'cbm_dealer') }
      let(:cpac_dealer)  { Dealer.find_by(dealer_code: 'cpac_dealer') }

      before do
        FactoryBot.create(:cbm_dealer,  dealer_code: 'cbm_dealer')
        FactoryBot.create(:cpac_dealer, dealer_code: 'cpac_dealer')

        ## cbm_dealer
        order5 = FactoryBot.create(:order, dealer: cbm_dealer, contractor: contractor)
        FactoryBot.create(:installment, order: order5, principal: 1000, paid_principal: 80)

        ## cpac_dealer
        # サイトオーダー(Open)
        site1 = FactoryBot.create(:site, contractor: contractor, dealer: cpac_dealer, site_credit_limit: 3000)
        order1 = FactoryBot.create(:order, dealer: cpac_dealer, contractor: contractor, site: site1)
        FactoryBot.create(:installment, order: order1, principal: 1000, paid_principal: 400)

        # サイトオーダー(Closed)
        site2 = FactoryBot.create(:site, :closed, contractor: contractor, site_credit_limit: 4000)
        order2 = FactoryBot.create(:order, dealer: cpac_dealer, contractor: contractor, site: site2)
        FactoryBot.create(:installment, order: order2, principal: 2000, paid_principal: 500)
      end

      it '指定Dealerのオーダーのみが対象になること' do
        expect(contractor.dealer_remaining_principal(cbm_dealer)).to eq 920
        expect(contractor.dealer_remaining_principal(cpac_dealer)).to eq 3000 + 1500
      end
    end
  end

  describe '#has_over_due_payment_contractors' do
    before do
      FactoryBot.create(:system_setting)
    end

    context 'status' do
      let(:contractor1) { FactoryBot.create(:contractor) }
      let(:contractor2) { FactoryBot.create(:contractor) }
      let(:contractor3) { FactoryBot.create(:contractor) }
      let(:contractor4) { FactoryBot.create(:contractor) }
      let(:due_ymd) { '20190215' }

      before do
        payment1 = FactoryBot.create(:payment, :over_due,    contractor: contractor1, due_ymd: due_ymd)
        payment2 = FactoryBot.create(:payment, :next_due,    contractor: contractor2, due_ymd: due_ymd)
        payment3 = FactoryBot.create(:payment, :not_due_yet, contractor: contractor3, due_ymd: due_ymd)
        payment4 = FactoryBot.create(:payment, :paid,        contractor: contractor4, due_ymd: due_ymd)

        order1 = FactoryBot.create(:order, :inputed_date)
        order2 = FactoryBot.create(:order, :inputed_date)
        order3 = FactoryBot.create(:order, :inputed_date)
        order4 = FactoryBot.create(:order, :inputed_date)

        FactoryBot.create(:installment, order: order1, payment: payment1)
        FactoryBot.create(:installment, order: order2, payment: payment2)
        FactoryBot.create(:installment, order: order3, payment: payment3)
        FactoryBot.create(:installment, order: order4, payment: payment4)
      end

      it '正しい値が取得できること' do
        expect(Contractor.has_over_due_payment_contractors).to eq [ contractor1 ]
      end
    end

    context 'paymentが複数' do
      let(:contractor) { FactoryBot.create(:contractor) }

      before do
        payment1 = FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20190215')
        payment2 = FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20190228')

        order1 = FactoryBot.create(:order, :inputed_date)
        order2 = FactoryBot.create(:order, :inputed_date)

        FactoryBot.create(:installment, order: order1, payment: payment1)
        FactoryBot.create(:installment, order: order2, payment: payment2)
      end

      it '正しい値が取得できること' do
        expect(Contractor.has_over_due_payment_contractors).to eq [ contractor ]
      end
    end

    context 'contractorが複数' do
      let(:contractor1) { FactoryBot.create(:contractor) }
      let(:contractor2) { FactoryBot.create(:contractor) }

      before do
        payment1 = FactoryBot.create(:payment, :over_due, contractor: contractor1, due_ymd: '20190215')
        payment2 = FactoryBot.create(:payment, :over_due, contractor: contractor2, due_ymd: '20190228')

        order1 = FactoryBot.create(:order, :inputed_date)
        order2 = FactoryBot.create(:order, :inputed_date)

        FactoryBot.create(:installment, order: order1, payment: payment1)
        FactoryBot.create(:installment, order: order2, payment: payment2)
      end

      it '正しい値が取得できること' do
        expect(Contractor.has_over_due_payment_contractors).to eq [
          contractor1, contractor2
        ]
      end
    end
  end

  # TODO テストを実装する
  describe '#calc_over_due_amount' do
    let(:contractor) { FactoryBot.create(:contractor) }

    before do
      FactoryBot.create(:business_day, business_ymd: '20190115')
    end

    context 'over_due以外のステータス' do
      before do
        payment1 = FactoryBot.create(:payment, :over_due,    contractor: contractor, due_ymd: '20190215')
        payment2 = FactoryBot.create(:payment, :next_due,    contractor: contractor, due_ymd: '20190215')
        payment3 = FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20190215')

        order1 = FactoryBot.create(:order, purchase_ymd: '20190101', input_ymd: '20190102')
        order2 = FactoryBot.create(:order, purchase_ymd: '20190101', input_ymd: '20190102')
        order3 = FactoryBot.create(:order, purchase_ymd: '20190101', input_ymd: '20190102')

        FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190215', principal: 100)
        FactoryBot.create(:installment, order: order2, payment: payment2, due_ymd: '20190215', principal: 200)
        FactoryBot.create(:installment, order: order3, payment: payment3, due_ymd: '20190215', principal: 400)
      end

      it 'over_dueのみが対象になること' do
        expect(contractor.calc_over_due_amount).to eq 100
      end
    end

    context 'cashbackとexceededが引かれること' do
      before do
        contractor.update!(pool_amount: 1)
        contractor.create_gain_cashback_history(2, '20190101', 0)

        payment1 = FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20190215')
        payment2 = FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20190215')

        order1 = FactoryBot.create(:order, purchase_ymd: '20190101', input_ymd: '20190102')
        order2 = FactoryBot.create(:order, purchase_ymd: '20190101', input_ymd: '20190102')

        FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190215', principal: 100)
        FactoryBot.create(:installment, order: order2, payment: payment2, due_ymd: '20190215', principal: 200)
      end

      it 'over_dueのみが対象になること' do
        expect(contractor.calc_over_due_amount).to eq 297
      end
    end
  end

  describe '#paid_over_due_payment_count' do
    let(:contractor) { FactoryBot.create(:contractor) }

    context '遅延中' do
      before do
        FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20190115', paid_up_ymd: nil)
      end

      it 'over_dueはカウントしない' do
        expect(contractor.paid_over_due_payment_count).to eq 0
      end
    end

    context '支払い済み' do
      before do
        # 期日内
        payment1 = FactoryBot.create(:payment, :paid, contractor: contractor, due_ymd: '20190115', paid_up_ymd: '20190114')
        payment2 = FactoryBot.create(:payment, :paid, contractor: contractor, due_ymd: '20190115', paid_up_ymd: '20190115')

        # 延滞
        payment3 = FactoryBot.create(:payment, :paid, contractor: contractor, due_ymd: '20190115', paid_up_ymd: '20190116')
        payment4 = FactoryBot.create(:payment, :paid, contractor: contractor, due_ymd: '20190115', paid_up_ymd: '20190117')
        payment5 = FactoryBot.create(:payment, :paid, contractor: contractor, due_ymd: '20190115', paid_up_ymd: '20190118')

        order1 = FactoryBot.create(:order, :inputed_date)
        order2 = FactoryBot.create(:order, :inputed_date)
        order3 = FactoryBot.create(:order, :inputed_date)
        order4 = FactoryBot.create(:order, :inputed_date)
        order4 = FactoryBot.create(:order, :inputed_date)

        FactoryBot.create(:installment, order: order1, payment: payment1)
        FactoryBot.create(:installment, order: order2, payment: payment2)
        FactoryBot.create(:installment, order: order3, payment: payment3)
        FactoryBot.create(:installment, order: order4, payment: payment4)
        FactoryBot.create(:installment, order: order4, payment: payment5)
      end

      it '支払い済みかつ遅延したPaymentのみが取得されること' do
        expect(contractor.paid_over_due_payment_count).to eq 3
      end
    end
  end

  describe '#cashback_use_ymd' do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:order) { FactoryBot.create(:order, :inputed_date, contractor: contractor) }

    before do
      payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20200301')
      FactoryBot.create(:installment, payment: payment, order: order)
    end

    context 'Paymentあり、運用でキャッシュバックを追加' do
      before do
        FactoryBot.create(:cashback_history, :latest, :gain, contractor: contractor, order: nil)
      end

      it 'order_id: null (運用対応)の場合にエラーにならないこと' do
        expect(contractor.cashback_use_ymd).to eq '20200301'
      end
    end

    context 'Paymentあり、同じPaymentでキャッシュバック発生' do
      before do
        FactoryBot.create(:cashback_history, :latest, :gain, contractor: contractor, order: order)
      end

      it 'Paymentの支払日が返らないこと' do
        expect(contractor.cashback_use_ymd).to eq nil
      end
    end

    context 'Paymentあり、違うPaymentでキャッシュバック発生' do
      let(:paid_order) { FactoryBot.create(:order, :inputed_date, contractor: contractor) }

      before do
        paid_payment = FactoryBot.create(:payment, :paid, contractor: contractor, due_ymd: '20200215')
        FactoryBot.create(:installment, payment: paid_payment, order: paid_order)

        FactoryBot.create(:cashback_history, :latest, :gain, contractor: contractor, order: paid_order)
      end

      it '次のPaymentの支払日が返ること' do
        expect(contractor.cashback_use_ymd).to eq '20200301'
      end
    end
  end

  describe '#create_gain_cashback_history' do
    let(:contractor) { FactoryBot.create(:contractor) }

    it '既存データなしでエラーにならないこと' do
      contractor.create_gain_cashback_history(10.0, '20200101', 1)
      contractor.reload

      expect(contractor.cashback_amount).to eq 10.0
    end

    it 'notes引数なしでnotesが定型文が入ること' do
      contractor.create_gain_cashback_history(10.0, '20200101', nil)
      contractor.reload

      expect(contractor.latest_cashback.notes).to eq 'Earned Cashback'
    end

    it 'notesを引数で設定できること' do
      contractor.create_gain_cashback_history(10.0, '20200101', nil, notes: 'some notes.')
      contractor.reload

      expect(contractor.latest_cashback.notes).to eq 'some notes.'
    end

    context '既存データあり' do
      before do
        contractor.create_gain_cashback_history(10.0, '20200101', nil)
      end

      it '既存データのlatestがfalseになること' do
        contractor.create_gain_cashback_history(20.0, '20200101', nil)
        contractor.reload

        expect(contractor.cashback_histories.find_by(cashback_amount: 10.0).latest).to eq false
      end

      it 'totalが正しく計算されること' do
        contractor.create_gain_cashback_history(20.0, '20200101', 1)
        contractor.reload

        expect(contractor.cashback_amount).to eq 30.0
      end
    end
  end

  describe '#create_use_cashback_history' do
    let(:contractor) { FactoryBot.create(:contractor) }

    context '既存データあり' do
      before do
        contractor.create_gain_cashback_history(30.0, '20200101', nil)
      end

      it '既存データのlatestがfalseになること' do
        contractor.create_use_cashback_history(20.0, '20200101')
        contractor.reload

        expect(contractor.cashback_histories.find_by(point_type: :gain).latest).to eq false
      end

      it 'totalが正しく計算されること' do
        contractor.create_use_cashback_history(20.0, '20200101')
        contractor.reload

        expect(contractor.cashback_amount).to eq 10.0
      end
    end
  end

  describe 'dealer_type_limit_amount' do
    let(:contractor) { FactoryBot.create(:contractor) }

    it 'レコードなしは0で返ること' do
      expect(contractor.dealer_type_limit_amount(:cbm).is_a?(Float)).to eq true
      expect(contractor.dealer_type_limit_amount(:cbm)).to eq 0
    end

    context '一部のレコードあり' do
      before do
        eligibility = FactoryBot.create(:eligibility, contractor: contractor)
        FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility, limit_amount: 12.34)
      end

      it '値が正しく取得されること' do

        expect(contractor.dealer_type_limit_amount(:cbm)).to eq 12.34
        expect(contractor.dealer_type_limit_amount(:cpac)).to eq 0
      end
    end
  end

  describe 'dealer_limit_amount' do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:dealer1) { FactoryBot.create(:dealer) }
    let(:dealer2) { FactoryBot.create(:dealer) }

    it 'レコードなしは0で返ること' do
      expect(contractor.dealer_limit_amount(dealer1).is_a?(Float)).to eq true
      expect(contractor.dealer_limit_amount(dealer1)).to eq 0
    end

    it 'contractorがuse_only_credit_limitでエラーにならないこと' do
      contractor.use_only_credit_limit = true

      contractor.dealer_limit_amount(dealer1)
    end

    context '一部のレコードあり' do
      
      before do
        eligibility = FactoryBot.create(:eligibility, :latest, contractor: contractor)
        FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer1, limit_amount: 12.34)
      end

      it '値が正しく取得されること' do
        expect(contractor.dealer_limit_amount(dealer1)).to eq 12.34
        expect(contractor.dealer_limit_amount(dealer2)).to eq 0
      end
    end
  end

  describe 'dealer_remaining_principal, dealer_type_remaining_principal' do
    context '9898のチケットサンプルパターン' do
      let(:contractor) { FactoryBot.create(:contractor) }
      let(:eligibility) { FactoryBot.create(:eligibility, contractor: contractor, limit_amount: 1000) }
      let(:dealer1) { FactoryBot.create(:cpac_dealer) }
      let(:dealer2) { FactoryBot.create(:cpac_dealer) }

      before do
        FactoryBot.create(:dealer_type_limit, :cpac, eligibility: eligibility, limit_amount: 1000)
        FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer1, limit_amount: 500)
        FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer2, limit_amount: 500)
      end

      it '値が正しいこと' do
        expect(contractor.available_balance).to eq 1000
        expect(contractor.dealer_type_available_balance(:cpac)).to eq 1000
        expect(contractor.dealer_available_balance(dealer1)).to eq 500
        expect(contractor.dealer_available_balance(dealer2)).to eq 500
      end

      context 'Siteを作成' do
        before do
          FactoryBot.create(:site, contractor: contractor, dealer: dealer1, site_credit_limit: 500)
        end

        let(:site) { contractor.sites.first }

        it '値が正しいこと' do
          expect(contractor.available_balance).to eq 500
          expect(contractor.dealer_type_available_balance(:cpac)).to eq 500
          expect(contractor.dealer_available_balance(dealer1)).to eq 0
          expect(contractor.dealer_available_balance(dealer2)).to eq 500

          expect(site.available_balance).to eq 500
        end

        context 'Dealer1を指定して100購入' do
          before do
            order = FactoryBot.create(:order, :inputed_date, contractor: contractor, dealer: dealer1,
              site: site, purchase_amount: 100)
            payment = FactoryBot.create(:payment, contractor: contractor, total_amount: 100)
            FactoryBot.create(:installment, order: order, principal: 100)
          end

          it 'site.available_balanceが400になること' do
            expect(contractor.available_balance).to eq 500
            expect(contractor.dealer_type_available_balance(:cpac)).to eq 500
            expect(contractor.dealer_available_balance(dealer1)).to eq 0
            expect(contractor.dealer_available_balance(dealer2)).to eq 500

            expect(site.available_balance).to eq 400
          end

          context 'Dealer2を指定して200購入' do
            before do
              order = FactoryBot.create(:order, :inputed_date, contractor: contractor, dealer: dealer2,
                site: site, purchase_amount: 200)
              payment = FactoryBot.create(:payment, contractor: contractor, total_amount: 200)
              FactoryBot.create(:installment, order: order, principal: 200)
            end

            it 'site.available_balanceが200になること' do
              expect(contractor.available_balance).to eq 500
              expect(contractor.dealer_type_available_balance(:cpac)).to eq 500
              expect(contractor.dealer_available_balance(dealer1)).to eq 0
              expect(contractor.dealer_available_balance(dealer2)).to eq 500

              expect(site.available_balance).to eq 200
            end

            context 'SiteをClose' do
              before do
                site.update!(closed: true)
              end

              it '通常のオーダーとしてAvailabelBalanceが計算されること' do
                expect(contractor.available_balance).to eq 700
                expect(contractor.dealer_type_available_balance(:cpac)).to eq 700
                expect(contractor.dealer_available_balance(dealer1)).to eq 400
                expect(contractor.dealer_available_balance(dealer2)).to eq 300
              end
            end
          end
        end
      end
    end
  end

  describe 'available_dealer_codes' do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:eligibility) { FactoryBot.create(:eligibility, contractor: contractor) }

    context '利用可能な設定(DealerTypeLimit設定)なし' do
      before do
        Product.all.each {|product|
          FactoryBot.create(:available_product, :cbm, :unavailable, product_id: product.id, contractor: contractor)
        }
      end

      it '空の配列が返ること' do
        expect(contractor.available_dealer_codes).to eq []
      end
    end

    context '利用可能な設定あり' do
      let(:cbm_dealer) { FactoryBot.create(:cbm_dealer, dealer_code: '12345') }

      before do
        Product.all.each {|product|
          FactoryBot.create(:available_product, :cbm, :available, product_id: product.id, contractor: contractor)
        }

        FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)
        FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: cbm_dealer)
      end

      it '利用可能なDealerCodeの配列が返ること' do
        expect(contractor.available_dealer_codes).to eq [cbm_dealer.dealer_code]
      end

      context '利用可能な設定をfalseへ' do
        before do
          contractor.available_products.update_all(available: false)
        end

        it '空の配列が返ること' do
          expect(contractor.available_dealer_codes).to eq []
        end
      end
    end
  end

  describe 'generate_application_number' do
    before do
      Timecop.travel(Time.new(2022, 5, 9, 12, 0, 0))
    end

    after do
      Timecop.return
    end

    it '最初の連番が正常に作成されること' do
      expect(Contractor.generate_application_number).to eq 'OLA-20220509-000000'
    end

    context '同日の番号がある' do
      before do
        FactoryBot.create(:contractor, application_number: 'OLA-20220509-000000')
      end

      it '同じ年度で番号が上がること' do
        expect(Contractor.generate_application_number).to eq 'OLA-20220509-000001'
      end
    end

    context '同年の番号がある' do
      before do
        FactoryBot.create(:contractor, application_number: 'OLA-20220101-000000')
      end

      it '同じ年度で番号が上がること' do
        expect(Contractor.generate_application_number).to eq 'OLA-20220509-000001'
      end
    end

    context '別年の番号がある' do
      before do
        FactoryBot.create(:contractor, application_number: 'OLA-20210509-000001')
      end

      it '別年で初期番号になること' do
        expect(Contractor.generate_application_number).to eq 'OLA-20220509-000000'
      end
    end

    context '複数の番号がある' do
      before do
        FactoryBot.create(:contractor, application_number: 'OLA-20210509-000000')
        FactoryBot.create(:contractor, application_number: 'OLA-20210509-000001')
        FactoryBot.create(:contractor, application_number: 'OLA-20220509-000000')
        FactoryBot.create(:contractor, application_number: 'OLA-20220509-000001')
      end

      it '採番が正しいこと' do
        expect(Contractor.generate_application_number).to eq 'OLA-20220509-000002'
      end
    end
  end
end
