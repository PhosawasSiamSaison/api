require 'rails_helper'

RSpec.describe OnlineApply::IndexController, type: :controller do

  describe '#check_tax_id' do
    it '未登録のtax_idがsuccess:trueになること' do
      params = {
        tax_id: "0000000000001"
      }

      get :check_tax_id, params: params

      expect(res[:success]).to eq true
    end

    context 'taken' do
      before do
        FactoryBot.create(:contractor, tax_id: '0000000000001')
        FactoryBot.create(:contractor, :pre_registration, application_type: :applied_online, tax_id: '0000000000002')
      end

      it '登録済みのtax_idがsuccess: falseになること' do
        params = {
          tax_id: "0000000000001"
        }

        get :check_tax_id, params: params
        expect(res[:success]).to eq false

        params = {
          tax_id: "0000000000002"
        }

        get :check_tax_id, params: params
        expect(res[:success]).to eq false
      end
    end
  end

  describe 'create_contractor' do
    let(:default_params) {
      {
        contractor: {
          tax_id: "0000000000001",
          th_company_name: "Company Name(Thai)",
          en_company_name: "Company Name(Eng)",
          phone_number: "0123456789",
          employee_count: "10",
          establish_year: "2022",
          shareholders_equity: 1,
          capital_fund_mil: "5",
          recent_revenue: -1,
          short_term_loan: 1.1,
          long_term_loan: 1.11,
          recent_profit: 999999999999.99,
          apply_from: "thai shop"
        },
        contractor_user: {
          user_name: "1000000000001",
          mobile_number: "0000000000",
          email: "a@mail.com",
          th_name: "Name-Surname (Thai)",
          en_name: "Name-Surname (Eng)",
          line_id: ""
        },
        documents: {
          company_certificate: {
            filename: "file1.png",
            data: sample_image_data_uri
          },
          vat_certification: {
            filename: "file2.png",
            data: sample_image_data_uri
          },
          office_store_map: {
            filename: "file3.png",
            data: sample_image_data_uri
          },
          financial_statement: {
            filename: "file4.png",
            data: sample_image_data_uri
          },
          copy_of_national_id: {
            filename: "file5.png",
            data: sample_image_data_uri
          }
        }
      }
    }

    it '正常に登録されること' do
      get :create_contractor, params: default_params

      expect(res[:success]).to eq true

      contractor = Contractor.first
      expect(contractor.tax_id).to eq default_params[:contractor][:tax_id]
      expect(res[:auth_token].present?).to eq true
      expect(contractor.online_apply_token).to eq res[:auth_token]
      expect(contractor.doc_company_certificate.attached?).to eq true
      expect(contractor.application_number.present?).to eq true
    end

    it 'invalid_contractor' do
      params = default_params.dup
      params[:contractor][:tax_id] = ''

      get :create_contractor, params: params

      expect(res[:success]).to eq false
      expect(res[:error]).to eq 'invalid_contractor'
    end

    it 'invalid_contractor_user' do
      params = default_params.dup
      params[:contractor_user][:user_name] = ''

      get :create_contractor, params: params

      expect(res[:success]).to eq false
      expect(res[:error]).to eq 'invalid_contractor_user'
    end

    it 'documentsがオプションであること' do
      params = default_params.dup
      params[:documents] = nil

      get :create_contractor, params: params

      expect(res[:success]).to eq true
    end
  end
end
