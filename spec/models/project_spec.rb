# == Schema Information
#
# Table name: projects
#
#  id                      :bigint(8)        not null, primary key
#  project_code            :string(255)      not null
#  project_type            :integer          not null
#  project_name            :string(255)      not null
#  project_manager_id      :bigint(8)        not null
#  project_value           :decimal(10, 2)
#  project_limit           :decimal(10, 2)   not null
#  delay_penalty_rate      :integer          not null
#  project_owner           :string(40)
#  start_ymd               :string(8)        not null
#  finish_ymd              :string(8)        not null
#  address                 :string(1000)
#  progress                :integer          default(0), not null
#  status                  :integer          default("opened"), not null
#  contract_registered_ymd :string(8)        not null
#  create_user_id          :bigint(8)        not null
#  update_user_id          :bigint(8)        not null
#  deleted                 :integer          default(0)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  operation_updated_at    :datetime
#  lock_version            :integer          default(0), not null
#

require 'rails_helper'

RSpec.describe Project, type: :model do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:project) { FactoryBot.create(:project, create_user: jv_user, update_user: jv_user) }
  
  describe "validates" do
    describe "project_code" do
      describe "nil" do
        before do
          project.project_code = nil
        end

        it "エラーになること" do
          project.valid?
          expect(project.errors.messages[:project_code]).to eq ["can't be blank"] 
        end
      end
    end

    describe "project_type" do
      describe "nil" do
        before do
          project.project_type = nil
        end
      
        it "エラーになること" do
          project.valid?
          expect(project.errors.messages[:project_type]).to eq ["can't be blank"]
        end
      end
    end

    describe "project_name" do
      describe "nil" do
        before do
          project.project_name = nil
        end
      
        it "エラーになること" do
          project.valid?
          expect(project.errors.messages[:project_name]).to eq ["can't be blank"]
        end
      end
    end

    describe "project_manager_id" do
      describe "nil" do
        before do
          project.project_manager_id = nil
        end
      
        it "エラーになること" do
          project.valid?
          expect(project.errors.messages[:project_manager]).to eq ["must exist"]
        end
      end
    end

    describe "project_value" do
      describe "比較" do
        it "project_limitより小さい場合はエラー" do
          project.project_value = 1000
          project.project_limit = 1001

          project.valid?

          expect(project.errors.messages[:project_limit])
            .to eq ["must be less than or equal to 1000.0"]
        end

        context 'Phaseあり' do
          before do
            FactoryBot.create(:project_phase, project: project, phase_value: 1000, phase_limit: 900)
          end

          it "Phase Limitの合計より下はエラー" do
            project.project_value = 999
            project.project_limit = 999

            project.valid?

            expect(project.errors.messages[:project_value])
              .to eq ["must be greater than or equal to 1000.0"]
          end
        end
      end
    end

    describe "project_limit" do
      describe "比較" do
        context 'Phaseあり' do
          before do
            FactoryBot.create(:project_phase, project: project, phase_value: 1100, phase_limit: 1000)
          end

          it "Phase Limitの合計より下はエラー" do
            project.project_value = 1100
            project.project_limit = 999

            project.valid?

            expect(project.errors.messages[:project_limit])
              .to eq ["must be greater than or equal to 1000.0"]
          end
        end
      end
    end

    describe "start_ymd" do
      describe "nil" do
        before do
          project.start_ymd = nil
        end
      
        it "エラーになること" do
          project.valid?
          expect(project.errors.messages[:start_ymd]).to eq ["can't be blank", "is the wrong length (should be 8 characters)"]
        end
      end
    end

    describe "finish_ymd" do
      describe "nil" do
        before do
          project.finish_ymd = nil
        end
      
        it "エラーになること" do
          project.valid?
          expect(project.errors.messages[:finish_ymd]).to eq ["can't be blank", "is the wrong length (should be 8 characters)"]
        end
      end
    end
  end

  describe "search" do
    describe "site_name" do
      before do
        project_phase = FactoryBot.create(:project_phase)

        FactoryBot.create(:project_phase_site, project_phase: project_phase, site_name: "site1")
        FactoryBot.create(:project_phase_site, project_phase: project_phase, site_name: "site2")
      end

      let(:default_params) {
        {
          search: {
            site_name: "",
          }
        }
      }

      it "１件だけ取得できること(joinsで結合していないこと)" do
        params = default_params.dup
        params[:search][:site_name] = "site"

        projects, total_count = Project.search(params)

        expect(projects.count).to eq 1
      end

      it "取得できないこと" do
        params = default_params.dup
        params[:search][:site_name] = "suzuki"

        projects, total_count = Project.search(params)

        expect(projects.count).to eq 0
      end
    end
  end
end
