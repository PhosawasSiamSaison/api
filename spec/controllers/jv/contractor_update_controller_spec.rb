require 'rails_helper'

RSpec.describe Jv::ContractorUpdateController, type: :controller do
  let(:dealer) { FactoryBot.create(:dealer, dealer_name: 'Dealer1') }
  let(:dealer2) { FactoryBot.create(:dealer, dealer_name: 'Dealer2') }
  let(:cpac_dealer) { FactoryBot.create(:dealer, dealer_type: :cpac) }

  let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:product3) { Product.find_by(product_key: 3) }
  let(:contractor) {
    FactoryBot.create(:contractor,
                      doc_company_registration:    true,
                      doc_vat_registration:        true,
                      doc_owner_id_card:           true,
                      doc_authorized_user_id_card: true,
                      doc_bank_statement:          true,
                      doc_tax_report:              true,

                      th_company_name:                      "th_company_name",
                      en_company_name:                      "en_company_name",
                      address:                              "company address",
                      phone_number:                         "0000000000",
                      registration_no:                      "0",
                      establish_year:                       "2019",
                      establish_month:                      "",
                      employee_count:                       "1",
                      capital_fund_mil:                     "100.0",
                      tax_id:                               "0000000000000",
                      status:                               "active",
                      stop_payment_sms:                     false,
                      enable_rudy_confirm_payment:          true,

                      th_owner_name:                        "th_owner_name",
                      en_owner_name:                        "en_owner_name",
                      owner_address:                        "owner_address",
                      owner_personal_id:                    "0000000000001",
                      owner_line_id:                        "owner_line_id",
                      owner_sex:                            "male",
                      owner_birth_ymd:                      "20190101",
                      owner_mobile_number:                  "0000000001",
                      owner_email:                          "owner@example.com",

                      authorized_person_name:               "authorized_person_name",
                      authorized_person_title_division:     "authorized_person",
                      authorized_person_email:              "authorized@exsample.com",
                      authorized_person_personal_id:        "0000000000002",
                      authorized_person_mobile_number:      "0000000002",
                      authorized_person_line_id:            "auth_line_id",

                      contact_person_name:                  "contact_person_name",
                      contact_person_title_division:        "contact_person",
                      contact_person_personal_id:           "0000000000003",
                      contact_person_email:                 "contact@exsample.com",
                      contact_person_mobile_number:         "0000000003",
                      contact_person_line_id:               "contact_line_id",
    )
  }

  describe "PATCH #update" do
    let (:update_params) {
      {
        auth_token: auth_token.token,
        available_settings: {
          purchase_use_global: true,
          switch_use_global: true,
          cashback_use_global: true,
        },
        applied_dealers: [
          {
            dealer_id: dealer.id,
            applied_ymd: "20200101",
          }
        ],
        contractor: {
          doc_company_registration:    true,
          doc_vat_registration:        true,
          doc_owner_id_card:           true,
          doc_authorized_user_id_card: true,
          doc_bank_statement:          false,
          doc_tax_report:              false,

          application_documents: {
            hoge: false, # テストだと空のハッシュがnilになるので適当な値を入れる
          },

          th_company_name:  "th_company_name_u",
          en_company_name:  "en_company_name_u",
          address:          "company address_u",
          phone_number:     "1000000000",
          registration_no:  "9",
          establish_year:   "2020",
          establish_month:  "01",
          employee_count:   "999",
          capital_fund_mil: "4567.89",
          tax_id:           "1000000000000",
          status:           "inactive",
          stop_payment_sms:      true,
          enable_rudy_confirm_payment: false,
          is_switch_unavailable: false,
          th_owner_name:       "th_owner_name_u",
          en_owner_name:       "en_owner_name_u",
          owner_address:       "owner address_u",
          owner_personal_id:   "1000000000001",
          owner_line_id:       "owner_line_id_u",
          owner_sex:           "female",
          owner_birth_ymd:     "20191231",
          owner_mobile_number: "1000000001",
          owner_email:         "hoge@example.com_u",
          authorized_person_name:           "auth_full_name_u",
          authorized_person_title_division: "auth_title_div_u",
          authorized_person_personal_id:    "1000000000002",
          authorized_person_email:          "authorized@exsample.com_u",
          authorized_person_mobile_number:  "1000000002",
          authorized_person_line_id:        "auth_line_id_u",
          contact_person_name:              "contact_name_u",
          contact_person_title_division:    "contact_title_div_u",
          contact_person_personal_id:       "1000000000003",
          contact_person_email:             "contact@exsample.com_u",
          contact_person_mobile_number:     "1000000003",
          contact_person_line_id:           "contact_line_id_u"
        }
      }
    }

    describe "正常値で更新出来ること" do
      it "更新ができること" do
        params = update_params.dup
        params[:contractor_id] = contractor.id

        patch :update_contractor, params: params

        expect(res[:success]).to eq true

        expect(Contractor.count).to eq 1
        updated_contractor = Contractor.last
        expect(updated_contractor.doc_company_registration).to eq true
        expect(updated_contractor.doc_vat_registration).to eq true
        expect(updated_contractor.doc_owner_id_card).to eq true
        expect(updated_contractor.doc_authorized_user_id_card).to eq true
        expect(updated_contractor.doc_bank_statement).to eq false
        expect(updated_contractor.doc_tax_report).to eq false

        expect(updated_contractor.main_dealer_id).to eq dealer.id
        expect(updated_contractor.th_company_name).to eq "th_company_name_u"
        expect(updated_contractor.en_company_name).to eq "en_company_name_u"
        expect(updated_contractor.address).to eq "company address_u"
        expect(updated_contractor.phone_number).to eq "1000000000"
        expect(updated_contractor.registration_no).to eq "9"
        expect(updated_contractor.establish_year).to eq "2020"
        expect(updated_contractor.establish_month).to eq "01"
        expect(updated_contractor.employee_count).to eq "999"
        expect(updated_contractor.capital_fund_mil).to eq "4567.89"
        expect(updated_contractor.tax_id).to eq "1000000000000"
        expect(updated_contractor.status).to eq "inactive"
        expect(updated_contractor.stop_payment_sms).to eq true
        expect(updated_contractor.enable_rudy_confirm_payment).to eq false

        expect(updated_contractor.th_owner_name).to eq "th_owner_name_u"
        expect(updated_contractor.en_owner_name).to eq "en_owner_name_u"
        expect(updated_contractor.owner_address).to eq "owner address_u"
        expect(updated_contractor.owner_personal_id).to eq "1000000000001"
        expect(updated_contractor.owner_line_id).to eq "owner_line_id_u"
        expect(updated_contractor.owner_sex).to eq "female"
        expect(updated_contractor.owner_birth_ymd).to eq "20191231"
        expect(updated_contractor.owner_mobile_number).to eq "1000000001"
        expect(updated_contractor.owner_email).to eq "hoge@example.com_u"

        expect(updated_contractor.authorized_person_name).to eq "auth_full_name_u"
        expect(updated_contractor.authorized_person_title_division).to eq "auth_title_div_u"
        expect(updated_contractor.authorized_person_personal_id).to eq "1000000000002"
        expect(updated_contractor.authorized_person_email).to eq "authorized@exsample.com_u"
        expect(updated_contractor.authorized_person_mobile_number).to eq "1000000002"
        expect(updated_contractor.authorized_person_line_id).to eq "auth_line_id_u"

        expect(updated_contractor.contact_person_name).to eq "contact_name_u"
        expect(updated_contractor.contact_person_title_division).to eq "contact_title_div_u"
        expect(updated_contractor.contact_person_personal_id).to eq "1000000000003"
        expect(updated_contractor.contact_person_email).to eq "contact@exsample.com_u"
        expect(updated_contractor.contact_person_mobile_number).to eq "1000000003"
        expect(updated_contractor.contact_person_line_id).to eq "contact_line_id_u"
      end
    end
  end

  describe "GET contractor" do
    it "値が取得できること" do
      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
      }
      get :contractor, params: params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true

      result_contractor = res[:contractor]
      target_keys       = [
        :id,
        :doc_company_registration,
        :doc_vat_registration,
        :doc_owner_id_card,
        :doc_authorized_user_id_card,
        :doc_bank_statement,
        :doc_tax_report,

        :th_company_name,
        :en_company_name,
        :address,
        :phone_number,
        :registration_no,
        :tax_id,
        :establish_year,
        :capital_fund_mil,
        :employee_count,
        :application_number,
        :status,
        :stop_payment_sms,
        :enable_rudy_confirm_payment,

        :th_owner_name,
        :en_owner_name,
        :owner_address,
        :owner_birth_ymd,
        :owner_mobile_number,
        :owner_personal_id,
        :owner_sex,
        :owner_email,
        :owner_line_id,

        :authorized_person_same_as_owner,
        :authorized_person_name,
        :authorized_person_title_division,
        :authorized_person_personal_id,
        :authorized_person_email,
        :authorized_person_mobile_number,
        :authorized_person_line_id,

        :contact_person_same_as_owner,
        :contact_person_same_as_authorized_person,
        :contact_person_name,
        :contact_person_title_division,
        :contact_person_personal_id,
        :contact_person_email,
        :contact_person_mobile_number,
        :contact_person_line_id,

        :updated_at
      ]

      target_keys.each do |key|
        expect(result_contractor.has_key?(key)).to eq true
      end
    end
  end
end
