require 'rails_helper'

RSpec.describe Jv::ContractorDetailController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:jv_user) { auth_token.tokenable }
  let(:contractor) { FactoryBot.create(:contractor) }

  describe 'GET notes ' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer1') }
    let(:contractor) {
      FactoryBot.create(:contractor,
                        main_dealer:        dealer,
                        approval_status:    "qualified")
    }
    it "登録した値で取得できること" do
      params = {
        contractor_id: contractor.id,
        auth_token:    auth_token.token
      }

      get :notes, params: params
      expect(response).to have_http_status(:success)

      expect(res[:success]).to eq true
      expect(res[:notes][:notes]).to eq contractor.notes
    end
  end

  describe 'PATCH notes ' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer1') }
    let(:contractor) {
      FactoryBot.create(:contractor,
                        main_dealer:        dealer,
                        approval_status:    "qualified")
    }
    it "更新できること" do
      params = {
        contractor_id: contractor.id,
        auth_token:    auth_token.token,
        notes:         {
          notes:         'updated_notes'
        }
      }

      patch :update_notes, params: params
      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true

      params2 = {
        contractor_id: contractor.id,
        auth_token:    auth_token.token
      }

      get :notes, params: params2
      expect(response).to have_http_status(:success)
      expect(res[:notes][:notes]).to eq 'updated_notes'
    end
  end

  describe 'PATCH エラー notes' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer1') }
    let(:contractor) {
      FactoryBot.create(:contractor,
                        main_dealer:        dealer,
                        approval_status:    "qualified")
    }
    it "長さエラーになること" do
      params = {
        contractor_id: contractor.id,
        auth_token:    auth_token.token,
        notes:         {
          notes:         "a" * 65_536
        }
      }

      patch :update_notes, params: params
      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq false
    end
  end

  describe 'GET basic_information' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer1') }
    let(:contractor) {
      FactoryBot.create(:contractor,
                        main_dealer:        dealer,
                        approval_status:    "qualified")
    }

    it "登録した値で取得できること" do
      params = {
        contractor_id: contractor.id,
        auth_token:    auth_token.token
      }

      get :basic_information, params: params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      bi = res[:basic_information]
      expect(bi[:tax_id]).to eq contractor.tax_id
      expect(bi[:th_company_name]).to eq contractor.th_company_name
      expect(bi[:en_company_name]).to eq contractor.en_company_name
      expect(bi[:employee_count]).to eq contractor.employee_count
      expect(bi[:status][:code]).to eq contractor.status
      expect(bi[:status][:label]).to eq 'Active'
      expect(bi[:capital_fund_mil]).to eq contractor.capital_fund_mil
      expect(bi[:application_number]).to eq contractor.application_number
      expect(bi.has_key?(:updated_at)).to eq true
      expect(bi.has_key?(:stop_payment_sms)).to eq true
      expect(bi.has_key?(:enable_rudy_confirm_payment)).to eq true
    end
  end

  describe 'GET more_information ' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer1') }
    let(:contractor) {
      FactoryBot.create(:contractor,
                        main_dealer:     dealer,
                        approval_status: "qualified")
    }

    it "定義したKey が取得できること" do
      target_keys = [:id,
                     :tax_id,
                     :application_type,
                     :approval_status,
                     :registered_at,
                     :status,
                     :th_company_name,
                     :en_company_name,
                     :address,
                     :phone_number,
                     :registration_no,
                     :establish_year,
                     :employee_count,
                     :capital_fund_mil,
                     :application_number,

                     :th_owner_name,
                     :en_owner_name,
                     :owner_address,
                     :owner_personal_id,
                     :owner_line_id,
                     :owner_sex,
                     :owner_birth_ymd,
                     :owner_mobile_number,
                     :owner_email,

                     :authorized_person_name,
                     :authorized_person_title_division,
                     :authorized_person_personal_id,
                     :authorized_person_email,
                     :authorized_person_mobile_number,
                     :authorized_person_line_id,

                     :contact_person_name,
                     :contact_person_title_division,
                     :contact_person_email,
                     :contact_person_mobile_number,
                     :contact_person_line_id,
                     :contact_person_personal_id,

                     :approved_at,
                     :rejected_at,
                     :updated_at,
                     :register_user_name,
                     :create_user_name,
                     :update_user_name,
                     :approval_user_name]
      params      = {
        contractor_id: contractor.id,
        auth_token:    auth_token.token
      }

      get :more_information, params: params
      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true

      contractor = res[:contractor]
      target_keys.each do |key|
        expect(contractor.has_key?(key)).to eq true
      end
    end
  end

  describe '#upload_qr_code_image' do
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:auth_token) { FactoryBot.create(:auth_token, tokenable: jv_user) }
    let(:contractor) { FactoryBot.create(:contractor) }

    it '画像の登録が成功すること' do
      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
        qr_code_image: sample_image_data_uri,
      }

      post :upload_qr_code_image, params: params
      expect(res[:success]).to eq true
      expect(contractor.reload.qr_code_updated_at.present?).to eq true
    end
  end

  describe '#qr_code' do
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:auth_token) { FactoryBot.create(:auth_token, tokenable: jv_user) }
    let(:contractor) { FactoryBot.create(:contractor) }

    it '画像の取得が成功すること' do
      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
        qr_code_image: sample_image_data_uri,
      }

      post :upload_qr_code_image, params: params
      expect(res[:success]).to eq true

      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
      }

      get :qr_code, params: params
      expect(res[:success]).to eq true
      expect(res[:updated_at].present?).to eq true
      expect(res[:qr_code_image_url].present?).to eq true
    end
  end

  describe '#site_list' do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }

    before do
      FactoryBot.create(:site, contractor: contractor)
    end

    it '正常に値が取得できること' do
      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id
      }
      get :site_list, params: params

      expect(res[:success]).to eq true
      site = res[:sites].first
      expect(site.present?).to eq true
      expect(site[:site_credit_limit].is_a?(Float)).to eq true
    end
  end

  describe '#site_reopen' do
    let(:site) { Site.first }

    before do
      FactoryBot.create(:site, :closed, contractor: contractor)
    end

    it '成功すること' do
      params = {
        auth_token: auth_token.token,
        id: site.id
      }
      patch :site_reopen, params: params

      expect(res[:success]).to eq true
      expect(site.reload.open?).to eq true
    end

    context 'staff' do
      before do
        auth_token.tokenable.staff!
      end

      it '権限エラーになること' do
        params = {
          auth_token: auth_token.token,
          id: site.id
        }
        patch :site_reopen, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.permission_denied')]
      end
    end
  end

  describe '#delay_penalty_rate' do
    it '取得できること' do
      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id
      }

      get :delay_penalty_rate, params: params

      expect(res[:success]).to eq true
      expect(res[:delay_penalty_rate]).to eq 18
      expect(res[:delay_penalty_rate].is_a?(Integer)).to eq true
    end
  end

  describe '#update_delay_penalty_rate' do
    it '更新できること' do
      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
        delay_penalty_rate: 20,
      }

      patch :update_delay_penalty_rate, params: params

      expect(res[:success]).to eq true
      expect(contractor.reload.delay_penalty_rate).to eq 20

      delay_penalty_rate_update_history = contractor.delay_penalty_rate_update_histories.first
      expect(delay_penalty_rate_update_history.old_rate).to eq 18
      expect(delay_penalty_rate_update_history.new_rate).to eq 20
      expect(delay_penalty_rate_update_history.update_user).to eq jv_user
    end

    it '不正値でエラーになること' do
      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
        delay_penalty_rate: -1,
      }

      patch :update_delay_penalty_rate, params: params

      expect(res[:success]).to eq false
      expect(res[:errors]).to eq ["Delay penalty rate must be greater than or equal to 0"]
      expect(contractor.reload.delay_penalty_rate).to eq 18
      expect(contractor.delay_penalty_rate_update_histories.count).to eq 0
    end
  end
end
