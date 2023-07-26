require 'rails_helper'

RSpec.describe Jv::ContractorRegistrationController, type: :controller do

  let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:jv_user) { FactoryBot.create(:jv_user) }

  describe "POST #register" do
    let(:dealer) { FactoryBot.create(:dealer, dealer_name: 'Dealer1') }
    let(:available_setting_dealer_types) {
      {
        cbm: [
          {product_key: 1, available: true},
          {product_key: 4, available: false},
          {product_key: 5, available: false},
          {product_key: 2, available: true},
          {product_key: 3, available: true}
        ],
        global_house: [
          {product_key: 1, available: true},
          {product_key: 4, available: true},
          {product_key: 5, available: false},
          {product_key: 2, available: true},
          {product_key: 3, available: true}
        ],
        transformer: [
          {product_key: 1, available: true},
          {product_key: 4, available: true},
          {product_key: 5, available: false},
          {product_key: 2, available: true},
          {product_key: 3, available: true}
        ],
        q_mix: [
          {product_key: 1, available: true},
          {product_key: 4, available: false},
          {product_key: 5, available: false},
          {product_key: 2, available: false},
          {product_key: 3, available: false}
        ],
        cpac: [
          {product_key: 1, available: true},
          {product_key: 4, available: false},
          {product_key: 5, available: false},
          {product_key: 2, available: false},
          {product_key: 3, available: false}
        ],
        solution: [
          {product_key: 1, available: true},
          {product_key: 4, available: false},
          {product_key: 5, available: false},
          {product_key: 2, available: false},
          {product_key: 3, available: false},
        ],
        b2b: [
          {product_key: 1, available: true},
          {product_key: 4, available: false},
          {product_key: 5, available: false},
          {product_key: 2, available: false},
          {product_key: 3, available: false}
        ],
        nam: [
          {product_key: 1, available: true},
          {product_key: 4, available: false},
          {product_key: 5, available: false},
          {product_key: 2, available: false},
          {product_key: 3, available: false}
        ],
        bigth: [
          {product_key: 1, available: true},
          {product_key: 4, available: true},
          {product_key: 5, available: false},
          {product_key: 2, available: true},
          {product_key: 3, available: true}
        ],
        permsin: [
          {product_key: 1, available: true},
          {product_key: 4, available: false},
          {product_key: 5, available: false},
          {product_key: 2, available: false},
          {product_key: 3, available: false}
        ],
        scgp: [
          {product_key: 1, available: true},
          {product_key: 4, available: false},
          {product_key: 5, available: false},
          {product_key: 2, available: false},
          {product_key: 3, available: false}
        ],
        rakmao: [
          {product_key: 1, available: true},
          {product_key: 4, available: true},
          {product_key: 5, available: false},
          {product_key: 2, available: true},
          {product_key: 3, available: true}
        ],
        cotto: [
          {product_key: 1, available: true},
          {product_key: 4, available: true},
          {product_key: 5, available: false},
          {product_key: 2, available: true},
          {product_key: 3, available: true}
        ],
        d_gov: [
          {product_key: 1, available: true},
          {product_key: 4, available: false},
          {product_key: 5, available: false},
          {product_key: 2, available: false},
          {product_key: 3, available: false}
        ],
      }
    }

    let (:default_params) {
      {
        auth_token: auth_token.token,
        available_settings: {
          purchase_use_global: false,
          switch_use_global: false,
          cashback_use_global: false,
          purchase: available_setting_dealer_types,
          switch: available_setting_dealer_types,
          cashback: {
            cbm: false,
            global_house: true,
            transformer: true,
            cpac: false,
            q_mix: false,
            solution: false,
            b2b: false,
            nam: false,
            bigth: false,
            permsin: false,
            scgp: false,
            rakmao: false,
            cotto: false,
            d_gov: false,
          }
        },
        applied_dealers: [
          {dealer_id: dealer.id, applied_ymd: "20200101"},
        ],
        contractor: {
          doc_company_registration:    true,
          doc_vat_registration:        true,
          doc_owner_id_card:           true,
          doc_authorized_user_id_card: true,
          doc_bank_statement:          true,
          doc_tax_report:              true,

          application_documents: {
            hoge: false, # テストだと空のハッシュがnilになるので適当な値を入れる
          },

          th_company_name:  "th_company_name",
          en_company_name:  "en_company_name",
          address:          "company address",
          phone_number:     "1234567890",
          registration_no:  "2345678901",
          establish_year:   "2019",
          employee_count:   "123",
          capital_fund_mil: "4567.89",
          tax_id:           "0000000000000",
          enable_rudy_confirm_payment: false,

          th_owner_name:       "th_owner_name",
          en_owner_name:       "en_owner_name",
          owner_address:       "owner address",
          owner_personal_id:   "0000000000000",
          owner_line_id:       "owner_line_id",
          owner_sex:           "male",
          owner_birth_ymd:     "20190213",
          owner_mobile_number: "22244445555",
          owner_email:         "hoge@example.com",

          authorized_person_name:           "auth_full_name",
          authorized_person_title_division: "authorized_person",
          authorized_person_personal_id:    "0000000000002",
          authorized_person_email:          "authorized@example.com",
          authorized_person_mobile_number:  "0000000000",
          authorized_person_line_id:        "auth_line_id",

          contact_person_name:           "contact_name",
          contact_person_title_division: "contact_person",
          contact_person_email:          "contact@exsample.com",
          contact_person_mobile_number:  "1111111111",
          contact_person_line_id:        "contact_line_id",
          contact_person_personal_id:    "0000000000003"
        }
      }
    }

    describe "すべてが正常値で登録" do
      it "register 登録ができること" do
        params = default_params.dup
        post :register, params: params

        expect(res[:success]).to eq true
        contractor = Contractor.last
        expect(contractor.present?).to eq true
        expect(contractor.processing?).to eq true
        expect(contractor.enable_rudy_confirm_payment).to eq false
      end

      it "factory" do
        expect(FactoryBot.create(:contractor)).to be_truthy
      end
    end

    describe "Draftで登録" do
      it "正常に登録ができること" do
        params = default_params.dup
        params[:save_as_draft] = true
        params[:contractor][:th_company_name] = "" # 空で登録
        post :register, params: params

        expect(res[:success]).to eq true
        contractor = Contractor.last
        expect(contractor.present?).to eq true
        expect(contractor.draft?).to eq true
      end
    end
  end
end
