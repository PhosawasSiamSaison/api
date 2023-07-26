require 'rails_helper'

RSpec.describe Jv::ProcessingDetailController, type: :controller do

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
    let(:contractor) {
      FactoryBot.create(:contractor, approval_status: "qualified")
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
      contractor.reload

      expect(res[:success]).to eq true
      expect(contractor.notes).to eq 'updated_notes'
    end
  end

  describe 'PATCH エラー　notes ' do
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

    end
  end

  describe 'GET more_information ' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer1') }
    let(:contractor) {
      FactoryBot.create(:contractor,
                        main_dealer:        dealer,
                        approval_status:    "qualified")
    }
    it "定義したKey が取得できること" do
      target_keys = [:id,
                     :tax_id,
                     :application_type,
                     :approval_status,
                     :application_number,
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
                     :authorized_person_mobile_number,
                     :authorized_person_line_id,
                     :authorized_person_personal_id,
                     :contact_person_name,
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

  describe 'GET contractor_users' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:jv_user) { auth_token.tokenable }
    let(:contractor) { FactoryBot.create(:contractor) }

    before do
      contractor.update!(authorized_person_same_as_owner: false,
        contact_person_same_as_owner: false,
        contact_person_same_as_authorized_person: false)
    end

    it '値が正常に取得できること' do
      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id
      }
      get :contractor_users, params: params
      expect(res[:success]).to eq true
      expect(res[:contractor_users].count).to eq 2

      contractor_user = res[:contractor_users].find do |user|
        user[:full_name] == contractor.th_owner_name
      end

      expect(contractor_user[:user_name]).to      eq contractor.owner_personal_id
      expect(contractor_user[:title_division]).to eq 'Owner'
      expect(contractor_user[:mobile_number]).to  eq contractor.owner_mobile_number
    end
  end

  describe 'PATCH approve_contractor' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:jv_user) { auth_token.tokenable }
    let(:contractor) { FactoryBot.create(:contractor) }

    before do
      FactoryBot.create(:eligibility, :latest, contractor: contractor)
    end

    describe 'Contractorの承認' do
      context '正常値' do
        it "正しく承認ができること" do
          params = {
            auth_token:              auth_token.token,
            contractor_id:           contractor.id
          }

          patch :approve_contractor, params: params

          expect(response).to have_http_status(:success)
          expect(res[:success]).to eq true

          contractor = Contractor.first
          expect(contractor.approval_status).to eq 'qualified'
          expect(contractor.approval_user).to eq jv_user
          expect(contractor.approved_at.present?).to eq true
        end
      end

      context 'Credit Limit 未登録' do
        before do
          Eligibility.update_all(deleted: true)
        end

        it "エラーメッセージが返ること" do
          params = {
            auth_token:              auth_token.token,
            contractor_id:           contractor.id
          }

          patch :approve_contractor, params: params
          expect(res[:success]).to eq false
          expect(res[:errors]).to eq [I18n.t("error_message.credit_limit_not_registered")]
        end
      end
    end

    describe 'ContractorUserの作成' do
      let(:params) {
        {
          auth_token:              auth_token.token,
          contractor_id:           contractor.id,
        }
      }

      it 'ユーザーが作成されること' do
        # 作成前のデータの確認
        users = contractor.contractor_users
        expect(users.present?).to eq false

        patch :approve_contractor, params: params
        expect(res[:success]).to eq true

        contractor.reload
        users = contractor.contractor_users
        expect(users.present?).to eq true
      end

      context 'personal_id の重複エラー' do
        before do
          personal_id = '1111111111111'
          FactoryBot.create(:contractor_user, user_name: personal_id)
          contractor.update!(owner_personal_id: personal_id)
        end

        it '重複でエラーになること' do
          patch :approve_contractor, params: params
          expect(response).to have_http_status(:success)
          expect(res[:success]).to eq false
          expect(res[:errors].present?).to eq true
        end
      end
    end
  end

  describe 'PATCH contractor reject' do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer1') }
    let(:contractor) {
      FactoryBot.create(:contractor,
                        main_dealer: dealer,
                        approval_status: "processing")
    }
    it "rejected 状態になること" do
      params = {
        contractor_id: contractor.id,
        auth_token:    auth_token.token,
      }

      patch :reject_contractor, params: params
      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      result_contractor = Contractor.find(contractor.id)
      expect(result_contractor.reject_user.nil?).to eq false
      expect(result_contractor.rejected_at.nil?).to eq false
      expect(result_contractor.approval_status).to eq 'rejected'

    end
  end
end

