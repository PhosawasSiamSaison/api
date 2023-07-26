require 'rails_helper'

RSpec.describe Jv::ProjectDetailController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:project) { FactoryBot.create(:project) }
  let(:project_phase) { FactoryBot.create(:project_phase, project: project) }
  let(:project_phase_site) { FactoryBot.create(:project_phase_site, project_phase: project_phase) }

  describe "#project" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_id: project.id
      }
    }

    it "値が取得できること" do
      get :project, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:project][:id]).to eq default_params[:project_id]
    end
  end

  describe "#search_photos" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_id: project.id,
        search: {
          contractor_id: project_phase_site.contractor.id,
          phase_id: project_phase.id
        }
      }
    }

    it "値が取得できること" do
      get :search_photos, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:photos].count).not_to eq 0
    end
  end

  describe "#update_project_photo_comment" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_photo_comment: {
          file_name: 'test.jpg',
          comment: 'test_comment',
        }
      }
    }

    describe "正常値" do
      it "登録できること" do
        patch :update_project_photo_comment, params: default_params

        expect(res[:success]).to eq true
        project_photo_comment = ProjectPhotoComment.find_by(file_name: default_params[:project_photo_comment][:file_name])

        expect(project_photo_comment.comment).to eq default_params[:project_photo_comment][:comment]
      end
    end

    describe "業務エラー" do
      it "エラーになること" do
        params = default_params.dup
        params[:project_photo_comment][:file_name] = ''

        patch :update_project_photo_comment, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [
          "File name can't be blank"
        ]
      end
    end
  end

  describe "#project_info_phases" do
    before do
      FactoryBot.create(:project_phase, project: project)
    end

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_id: project.id
      }
    }

    it "値が取得できること" do
      get :project_info_phases, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:phases].first[:id]).to eq ProjectPhase.first.id
    end
  end

  describe "#project_info_contractors" do
    before do
      project_phasse = FactoryBot.create(:project_phase, project: project)
      FactoryBot.create(:project_phase_site, project_phase: project_phase)
    end

    let(:project_phase_site) { ProjectPhaseSite.last }

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_id: project.id
      }
    }

    it "値が取得できること" do
      get :project_info_contractors, params: default_params

      expect(res[:success]).to eq true
      expect(res[:contractors].first[:id]).to eq project.contractors.first.id
    end
  end

  describe "#create_project_phase" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_id: project.id,
        phase: {
          phase_name: "phase_name_1",
          phase_value: 1000,
          start_ymd: "20211118",
          finish_ymd: "20211130",
          due_ymd: "20211110"
        }
      }
    }

    describe "正常値" do
      let(:project_phase) { ProjectPhase.last }

      it "登録できること" do
        post :create_project_phase, params: default_params

        expect(res[:success]).to eq true

        expect(project_phase.phase_name).to eq default_params[:phase][:phase_name]
        expect(project_phase.phase_value).to eq default_params[:phase][:phase_value]
        expect(project_phase.start_ymd).to eq default_params[:phase][:start_ymd]
        expect(project_phase.finish_ymd).to eq default_params[:phase][:finish_ymd]
        expect(project_phase.due_ymd).to eq default_params[:phase][:due_ymd]
      end
    end

    describe "業務エラー" do
      it "エラーになること" do
        params = default_params.dup
        params[:phase][:phase_name] = ''
        params[:phase][:start_ymd] = ''
        params[:phase][:finish_ymd] = ''
        params[:phase][:due_ymd] = ''

        post :create_project_phase, params: params

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

    describe "PhaseNumber期待値" do
      let(:project_phase) { ProjectPhase.last }

      it "想定した値になること" do
        post :create_project_phase, params: default_params
        post :create_project_phase, params: default_params

        expect(project_phase.phase_number).to eq 2
      end
    end
  end

  describe "#project_phase_list" do
    before do
      FactoryBot.create(:project_phase, project: project)
    end

    let(:params) {
      {
        auth_token: auth_token.token,
        project_id: project.id
      }
    }

    it "値が取得できること" do
      get :project_phase_list, params: params

      expect(res[:success]).to eq true
      expect(res[:phases].first[:id]).to eq project.project_phases.first.id
    end
  end

  describe "#project_documents" do
    before do
      params = {
        auth_token: auth_token.token,
        project_id: project.id,
        project_document: {
          file_type: "right_transfer_agreement",
          file_name: "test_file.png",
          ymd: "20190101",
          comment: "test_comment",
          file_data: sample_image_data_uri
        }
      }

      post :upload_project_document, params: params
      expect(res[:success]).to eq true
    end

    let(:params) {
      {
        auth_token: auth_token.token,
        project_id: project.id
      }
    }

    it "値が取得できること" do
      get :project_documents, params: params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:documents].first[:id]).to eq project.project_documents.first.id
    end
  end

  describe "#project_document" do
    before do
      params = {
        auth_token: auth_token.token,
        project_id: project.id,
        project_document: {
          file_type: "right_transfer_agreement",
          file_name: "test_file.png",
          ymd: "20190101",
          comment: "test_comment",
          file_data: sample_image_data_uri
        }
      }

      post :upload_project_document, params: params
      expect(res[:success]).to eq true
    end

    let(:project_document) { ProjectDocument.last }

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_document_id: project_document.id
      }
    }

    it "値が取得できること" do
      get :project_document, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:document][:id]).to eq default_params[:project_document_id]
    end
  end

  describe "#upload_project_document" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_id: project.id,
        project_document: {
          file_type: "right_transfer_agreement",
          file_name: "test_file.png",
          comment: "test_comment",
          file_data: sample_image_data_uri
        }
      }
    }

    describe "正常値" do
      let(:project_document) { ProjectDocument.last }

      it "登録できること" do
        post :upload_project_document, params: default_params

        expect(res[:success]).to eq true
        expect(project_document.file_type).to eq default_params[:project_document][:file_type]
        expect(project_document.file_name).to eq default_params[:project_document][:file_name]
        expect(project_document.comment).to eq default_params[:project_document][:comment]
        expect(project_document.file.attached?).to eq true
      end
    end

    describe "業務エラー" do
      it "エラーになること" do
        params = default_params.dup
        params[:project_document][:file_type] = ''
        params[:project_document][:file_name] = ''

        patch :upload_project_document, params: params

        expect(res[:success]).to eq false

        expect(res[:errors]).to eq [
            "File type can't be blank",
            "File name can't be blank"
        ]
      end
    end
  end

  describe "#update_project_document" do
    before do
      params = {
        auth_token: auth_token.token,
        project_id: project.id,
        project_document: {
          file_type: "right_transfer_agreement",
          file_name: "test_file.png",
          comment: "test_comment",
          file_data: sample_image_data_uri
        }
      }

      post :upload_project_document, params: params
      expect(res[:success]).to eq true
    end

    let(:project_document) { ProjectDocument.last }

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_document_id: project_document.id,
        project_document: {
          file_type: "phase_delivery_letter",
          comment: "test_comment_update"
        }
      }
    }

    describe "正常値" do
      it "登録できること" do
        patch :update_project_document, params: default_params

        expect(res[:success]).to eq true
        project_document.reload

        expect(project_document.file_type).to eq default_params[:project_document][:file_type]
        expect(project_document.comment).to eq default_params[:project_document][:comment]
      end
    end

    describe "業務エラー" do
      it "エラーになること" do
        params = default_params.dup
        params[:project_document][:file_type] = ''

        patch :update_project_document, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [
            "File type can't be blank",
        ]
      end
    end
  end

  describe "#delete_project_document" do
    before do
      params = {
        auth_token: auth_token.token,
        project_id: project.id,
        project_document: {
          file_type: "right_transfer_agreement",
          file_name: "test_file.png",
          comment: "test_comment",
          file_data: sample_image_data_uri
        }
      }

      post :upload_project_document, params: params
      expect(res[:success]).to eq true
    end

    let(:project_document) { ProjectDocument.last }

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_document_id: project_document.id
      }
    }

    it "削除できること" do
      delete :delete_project_document, params: default_params

      expect(res[:success]).to eq true
    end
  end

end