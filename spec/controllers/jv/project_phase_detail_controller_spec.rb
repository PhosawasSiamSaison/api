require 'rails_helper'

RSpec.describe Jv::ProjectPhaseDetailController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:project) { FactoryBot.create(:project) }
  let(:project_phase) { FactoryBot.create(:project_phase, project: project) }
  let(:project_phase_site) { FactoryBot.create(:project_phase_site, project_phase: project_phase) }

  def parse_base64(image)
    base64_image  = image.sub(/^data:.*,/, '')
    decoded_image = Base64.urlsafe_decode64(base64_image)
    StringIO.new(decoded_image)
  end

  describe "#project_phase" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id
      }
    }

    it "値が取得できること" do
      get :project_phase, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:phase][:id]).to eq default_params[:project_phase_id]
    end
  end

  describe "#update_project_phase" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id,
        phase: {
          phase_name: "phase_name_update",
          phase_value: 5000.0,
          start_ymd: "20220101",
          finish_ymd: "20220201",
          due_ymd: "20220101",
          status: :closed
        }
      }
    }

    describe "正常値" do
      it "登録できること" do
        patch :update_project_phase, params: default_params

        expect(res[:success]).to eq true
        project_phase.reload

        expect(project_phase.phase_name).to eq default_params[:phase][:phase_name]
        expect(project_phase.phase_value).to eq default_params[:phase][:phase_value]
        expect(project_phase.start_ymd).to eq default_params[:phase][:start_ymd]
        expect(project_phase.finish_ymd).to eq default_params[:phase][:finish_ymd]
        expect(project_phase.due_ymd).to eq default_params[:phase][:due_ymd]
        expect(project_phase.status.to_sym).to eq default_params[:phase][:status]
      end
    end

    describe "業務エラー" do
      it "エラーになること" do
        params = default_params.dup
        params[:phase][:phase_name] = ''
        params[:phase][:start_ymd] = ''
        params[:phase][:finish_ymd] = ''
        params[:phase][:due_ymd] = ''

        patch :update_project_phase, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [
          "Phase name can't be blank",
          "Start ymd can't be blank",
          "Start ymd is the wrong length (should be 8 characters)",
          "Finish ymd can't be blank",
          "Finish ymd is the wrong length (should be 8 characters)",
          "Due ymd can't be blank",
          "Due ymd is the wrong length (should be 8 characters)"
        ]
      end
    end
  end

  describe "#delete_project_phase" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id
      }
    }

    it "削除できること" do
      delete :delete_project_phase, params: default_params

      expect(res[:success]).to eq true
    end
  end

  describe "#project_basic_information" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id
      }
    }

    it "値が取得できること" do
      get :project_basic_information, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:project][:project_code]).to eq project_phase.project.project_code
      expect(res[:project][:project_name]).to eq project_phase.project.project_name
    end
  end

  describe "#evidence_list" do
    before do
      evidence = FactoryBot.create(:project_phase_evidence, project_phase: project_phase)
      evidence.file.attach(io: parse_base64(sample_image_data_uri), filename: 'test.png')
    end

    let(:evidence) { ProjectPhaseEvidence.last }

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id
      }
    }

    it "値が取得できること" do
      get :evidence_list, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:evidences].first[:id]).to eq project_phase.project_phase_evidences.first.id
    end
  end

  describe "#evidence" do
    before do
      evidence = FactoryBot.create(:project_phase_evidence, project_phase: project_phase)
      evidence.file.attach(io: parse_base64(sample_image_data_uri), filename: 'test.png')
    end

    let(:evidence) { ProjectPhaseEvidence.last }

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_evidence_id: evidence.id
      }
    }

    it "値が取得できること" do
      get :evidence, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:evidence][:id]).to eq default_params[:project_phase_evidence_id]
    end
  end

  describe "#update_evidence_check" do
    before do
      evidence = FactoryBot.create(:project_phase_evidence, project_phase: project_phase)
      evidence.file.attach(io: parse_base64(sample_image_data_uri), filename: 'test.png')
    end

    let(:evidence) { ProjectPhaseEvidence.last }

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_evidence_id: evidence.id,
        update_evidence_check_to: true
      }
    }

    describe "未チェック時" do
      it "登録できること" do
        request.env["CONTENT_TYPE"] = 'application/json'
        patch :update_evidence_check, params: default_params

        evidence.reload

        expect(evidence.checked_at).not_to eq nil
        expect(evidence.checked_user).not_to eq nil
      end
    end

    describe "チェック済時" do
      it "登録できること" do
        params = default_params.dup
        params[:update_evidence_check_to] = false
        request.env["CONTENT_TYPE"] = 'application/json'
        patch :update_evidence_check, params: params

        evidence.reload

        expect(evidence.checked_at).to eq nil
        expect(evidence.checked_user).to eq nil
      end
    end
  end

  describe "#payment_detail" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id,
      }
    }

    it "値が取得できること" do
      get :payment_detail, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:due_ymd]).to eq project_phase.due_ymd
      expect(res[:phase_value]).to eq project_phase.phase_value
    end
  end

  describe "#project_phase_site_list" do
    before do
      FactoryBot.create(:project_phase_site, project_phase: project_phase)
      FactoryBot.create(:business_day)
    end

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id,
        target_ymds: {project_phase.project_phase_sites.first.id => BusinessDay.today_ymd}.to_json
      }
    }

    it "値が取得できること" do
      get :project_phase_site_list, params: default_params

      expect(res[:success]).to eq true
      expect(res[:sites].first[:id]).to eq project_phase.project_phase_sites.first.id
    end
  end

  describe "#project_phase_site" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_site_id: project_phase_site.id,
      }
    }

    it "値が取得できること" do
      get :project_phase_site, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:site][:id]).to eq default_params[:project_phase_site_id]
    end
  end

  describe "#create_project_phase_site" do
    let(:contractor) { FactoryBot.create(:contractor) }

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id,
        contractor_id: contractor.id,
        project_phase_site: {
          site_code: "ST0001",
          site_name: "site_name_1",
          phase_limit: 1000.0,
        }
      }
    }

    describe "正常値" do
      let(:project_phase_site) { ProjectPhaseSite.last }

      it "登録できること" do
        post :create_project_phase_site, params: default_params

        expect(res[:success]).to eq true

        expect(project_phase_site.site_code).to eq default_params[:project_phase_site][:site_code]
        expect(project_phase_site.site_name).to eq default_params[:project_phase_site][:site_name]
        expect(project_phase_site.phase_limit).to eq default_params[:project_phase_site][:phase_limit]
        expect(project_phase_site.site_limit).to eq 0
      end
    end

    describe "業務エラー" do
      let(:proejct_phase_site) { ProjectPhaseSite.last }

      it "エラーになること" do
        params = default_params.dup
        params[:project_phase_site][:site_code] = ''
        params[:project_phase_site][:site_name] = ''

        post :create_project_phase_site, params: params

        expect(res[:success]).to eq false

        expect(res[:errors]).to eq [
          "Site code can't be blank",
          "Site name can't be blank",
        ]
      end

      context '既存のSiteあり' do
        before do
          post :create_project_phase_site, params: default_params
        end

        it "Contractorの重複チェック" do
          params = default_params.dup
          params[:project_phase_site][:site_code] = 'site2'

          post :create_project_phase_site, params: params

          expect(res[:success]).to eq false

          expect(res[:errors]).to eq ["Contractor has already been taken"]
        end
      end
    end
  end

  describe "#update_project_phase_site" do
    let(:contractor) { FactoryBot.create(:contractor) }

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_site_id: project_phase_site.id,
        contractor_id: contractor.id,
        project_phase_site: {
          site_code: "ST0001",
          site_name: "site_name_1",
          phase_limit: 1000.0,
        }
      }
    }

    describe "正常値" do
      it "登録できること" do
        patch :update_project_phase_site, params: default_params

        expect(res[:success]).to eq true
        project_phase_site.reload

        # site_codeは更新できないこと
        expect(project_phase_site.site_code).to_not eq default_params[:project_phase_site][:site_code]
        expect(project_phase_site.site_name).to eq default_params[:project_phase_site][:site_name]
        expect(project_phase_site.phase_limit).to eq default_params[:project_phase_site][:phase_limit]
      end
    end

    describe "業務エラー" do
      let(:proejct_phase_site) { ProjectPhaseSite.last }

      it "エラーになること" do
        params = default_params.dup
        params[:project_phase_site][:site_name] = ''

        patch :update_project_phase_site, params: params

        expect(res[:success]).to eq false

        expect(res[:errors]).to eq [
          "Site name can't be blank",
        ]
      end
    end
  end

  describe "#delete_project_phase_site" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_site_id: project_phase_site.id
      }
    }

    it "削除できること" do
      delete :delete_project_phase_site, params: default_params

      expect(res[:success]).to eq true
    end
  end

  describe '#receive_amount_history' do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id,
        page: 1,
        per_page: 10,
      }
    }

    before do
      FactoryBot.create(:project_receive_amount_history, project_phase_site: project_phase_site)
    end

    describe "正常値" do
      it "正常に取得できること" do
        get :receive_amount_history, params: default_params

        expect(res[:success]).to eq true

        project_receive_amount_histories = res[:receive_amount_histories]
        expect(project_receive_amount_histories.count).to eq 1
      end
    end
  end

  describe '#update_history_comment' do
    let(:project_receive_amount_history) {
      FactoryBot.create(:project_receive_amount_history, project_phase_site: project_phase_site)
    }
    let(:default_params) {
      {
        auth_token: auth_token.token,
        receive_amount_history: {
          id: project_receive_amount_history.id,
          comment: "update comment"
        }
      }
    }

    describe "更新" do
      it "正常" do
        patch :update_history_comment, params: default_params

        expect(res[:success]).to eq true
        expect(project_receive_amount_history.reload.comment).to eq 'update comment'
      end
    end
  end
end
