require 'rails_helper'

RSpec.describe Contractor::ProjectDetailController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :contractor) }
  let(:contractor) { auth_token.tokenable.contractor }
  let(:jv_user) { FactoryBot.create(:jv_user) }

  before do
    FactoryBot.create(:business_day)
  end

  describe "#project" do
    before do
      FactoryBot.create(:project_phase_site, contractor: contractor, create_user: jv_user, update_user: jv_user)
    end

    let(:project) { Project.last }

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_id: project.id
      }
    }

    it "値が取得できること" do
      get :project, params: default_params

      expect(res[:success]).to eq true
      expect(res[:project][:id]).to eq default_params[:project_id]
    end
  end

  describe "#project_phase_list" do
    let(:contractor2) { FactoryBot.create(:contractor, tax_id: '2222222222222') }

    let(:project1) { FactoryBot.create(:project, project_code: 'P1', create_user: jv_user, update_user: jv_user) }

    let(:project_phase1) { FactoryBot.create(:project_phase, project: project1, phase_name: 'Phase1') }
    let(:project_phase2) { FactoryBot.create(:project_phase, project: project1, phase_name: 'Phase2') }

    let(:project_phase_site1) {
      FactoryBot.create(:project_phase_site, project_phase: project_phase1, contractor: contractor, create_user: jv_user, update_user: jv_user) }
    let(:project_phase_site2) {
      FactoryBot.create(:project_phase_site, project_phase: project_phase1, contractor: contractor2, create_user: jv_user, update_user: jv_user) }
    let(:project_phase_site3) {
      FactoryBot.create(:project_phase_site, project_phase: project_phase2, contractor: contractor, create_user: jv_user) }

    let(:order1) { FactoryBot.create(:order, :inputed_date, contractor: contractor,
      project_phase_site: project_phase_site1, order_number: 'A') }
    let(:order2) { FactoryBot.create(:order, :inputed_date, contractor: contractor2,
      project_phase_site: project_phase_site2, order_number: 'B') }
    let(:order3) { FactoryBot.create(:order, :inputed_date, contractor: contractor,
      project_phase_site: project_phase_site3, order_number: 'C') }
    let(:order4) { FactoryBot.create(:order, :inputed_date, contractor: contractor,
      project_phase_site: project_phase_site3, order_number: 'D') }

    before do
      FactoryBot.create(:installment, order: order1, principal: 100, interest: 10, due_ymd: '20190215')
      FactoryBot.create(:installment, order: order2, principal: 200, interest: 20, due_ymd: '20190215')
      FactoryBot.create(:installment, order: order3, principal: 400, interest: 40, due_ymd: '20190215')
      FactoryBot.create(:installment, order: order4, principal: 800, interest: 80, due_ymd: '20190215')
    end

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_id: project1.id
      }
    }

    it "値が取得できること" do
      get :project_phase_list, params: default_params

      expect(res[:success]).to eq true

      phases = res[:phases]
      expect(phases.count).to eq 2

      phase1 = phases.find{|phase| phase[:phase_name] == 'Phase1'}
      orders = phase1[:orders]
      expect(orders.count).to eq 1
      expect(orders.first[:order_number]).to eq 'A'

      phase2 = phases.find{|phase| phase[:phase_name] == 'Phase2'}
      orders = phase2[:orders]
      expect(orders.count).to eq 2
      expect(orders.first[:order_number]).to eq 'C'
      expect(orders.second[:order_number]).to eq 'D'
    end
  end
end
