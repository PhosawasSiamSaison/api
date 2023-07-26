require 'rails_helper'

RSpec.describe Contractor::TopController, type: :controller do
  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20190116')
  end

  let(:contractor) { contractor_user.contractor }
  let(:contractor_user) { FactoryBot.create(:contractor_user)}
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: contractor_user).token }

  describe "GET #payment" do
    context 'next_payment あり' do
      let(:order) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20190115') }

      before do
        payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215')
        FactoryBot.create(:installment,
          order: order, payment: payment, due_ymd: '20190215', principal: order.purchase_amount)
      end

      it '正常に取得できること' do
        params = {
          auth_token: auth_token
        }

        get :payment, params: params
        expect(res[:success]).to eq true

        payment = res[:payment]
        expect(payment[:checking_payment]).to eq false
        expect(payment[:exist_over_due_amount]).to eq false
        expect(payment[:over_due_amount]).to eq 0.0

        next_payment = payment[:next_payment]
        expect(next_payment).to_not eq nil
        expect(next_payment[:status]).to eq 'next_due'
        expect(next_payment[:date]).to eq '20190215'
        expect(next_payment[:amount]).to eq order.purchase_amount
      end
    end

    context 'next_payment なし' do
      it 'next_paymentがnilで取得できること' do
        params = {
          auth_token: auth_token
        }

        get :payment, params: params
        expect(res[:success]).to eq true

        payment = res[:payment]
        expect(payment[:checking_payment]).to eq false
        expect(payment[:exist_over_due_amount]).to eq false
        expect(payment[:over_due_amount]).to eq 0.0

        expect(res[:payment][:next_payment]).to eq nil
      end
    end
  end

  describe 'GET #projects' do
    let(:contractor2) { FactoryBot.create(:contractor, tax_id: '2222222222222') }
    let(:contractor3) { FactoryBot.create(:contractor, tax_id: '3333333333333') }

    let(:project1) { FactoryBot.create(:project, project_code: 'P1') }
    let(:project2) { FactoryBot.create(:project, project_code: 'P2') }

    let(:project_phase1) { FactoryBot.create(:project_phase, project: project1, phase_name: 'Phase1') }
    let(:project_phase2) { FactoryBot.create(:project_phase, project: project2, phase_name: 'Phase2') }

    let(:project_phase_site1) { FactoryBot.create(:project_phase_site, project_phase: project_phase1, contractor: contractor) }
    let(:project_phase_site2) { FactoryBot.create(:project_phase_site, project_phase: project_phase1, contractor: contractor2) }
    let(:project_phase_site3) { FactoryBot.create(:project_phase_site, project_phase: project_phase2, contractor: contractor3) }

    let(:order1) { FactoryBot.create(:order, :inputed_date, contractor: contractor,
      project_phase_site: project_phase_site1) }
    let(:order2) { FactoryBot.create(:order, :inputed_date, contractor: contractor2,
      project_phase_site: project_phase_site1) }
    let(:order3) { FactoryBot.create(:order, :inputed_date, contractor: contractor3,
      project_phase_site: project_phase_site2) }

    before do
      FactoryBot.create(:installment, order: order1, principal: 100, interest: 10, due_ymd: '20190215')
      FactoryBot.create(:installment, order: order2, principal: 200, interest: 20, due_ymd: '20190215')
      FactoryBot.create(:installment, order: order3, principal: 400, interest: 40, due_ymd: '20190215')
    end

    it '他のContractorのデータが入らないこと' do
      params = {
        auth_token: auth_token
      }

      get :projects, params: params
      expect(res[:success]).to eq true

      projects = res[:projects]
      expect(projects.count).to eq 1

      project = projects.first
      expect(project[:next_payment][:amount]).to eq 110
    end
  end
end
