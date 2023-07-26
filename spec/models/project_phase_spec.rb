# == Schema Information
#
# Table name: project_phases
#
#  id                   :bigint(8)        not null, primary key
#  project_id           :bigint(8)        not null
#  phase_number         :integer          not null
#  phase_name           :string(255)      not null
#  phase_value          :decimal(10, 2)   not null
#  phase_limit          :decimal(10, 2)   default(0.0)
#  start_ymd            :string(8)        not null
#  finish_ymd           :string(8)        not null
#  due_ymd              :string(8)        not null
#  paid_up_ymd          :string(8)
#  status               :integer          default("not_opened_yet"), not null
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

require 'rails_helper'

RSpec.describe ProjectPhase, type: :model do
  let(:project_phase) { FactoryBot.create(:project_phase) }

  describe "validates" do
    describe "phase_name" do
      describe "nil" do
        before do
          project_phase.phase_name = nil
        end
      
        it "エラーになること" do
          project_phase.valid?
          expect(project_phase.errors.messages[:phase_name]).to eq ["can't be blank"]  
        end
      end
    end

    describe "start_ymd" do
      describe "nil" do
        before do
          project_phase.start_ymd = nil
        end
      
        it "エラーになること" do
          project_phase.valid?
          expect(project_phase.errors.messages[:start_ymd]).to eq [
            "can't be blank",
            "is the wrong length (should be 8 characters)"
          ]  
        end
      end
    end

    describe "finish_ymd" do
      describe "nil" do
        before do
          project_phase.finish_ymd = nil
        end
      
        it "エラーになること" do
          project_phase.valid?
          expect(project_phase.errors.messages[:finish_ymd]).to eq [
            "can't be blank",
            "is the wrong length (should be 8 characters)"
          ]
        end
      end
    end

    describe "due_ymd" do
      describe "nil" do
        before do
          project_phase.due_ymd = nil
        end
      
        it "エラーになること" do
          project_phase.valid?
          expect(project_phase.errors.messages[:due_ymd]).to eq [
            "can't be blank",
            "is the wrong length (should be 8 characters)"
          ]
        end
      end
    end

    describe '比較' do
      it 'phase_value >= phase_limit' do
        project_phase.phase_value = 1001
        project_phase.phase_limit = 1000
        project_phase.valid?
        expect(project_phase.errors.count).to eq 0

        project_phase.phase_value = 1000
        project_phase.phase_limit = 1000
        project_phase.valid?
        expect(project_phase.errors.count).to eq 0

        project_phase.phase_value = 1000
        project_phase.phase_limit = 1001
        project_phase.valid?
        expect(project_phase.errors.count).to eq 1
        expect(project_phase.errors[:phase_limit]).to eq ["must be less than or equal to 1000.0"]
      end

      it '' do
        project_phase.project.project_value = 1100
        project_phase.project.project_limit = 1000

        project_phase.phase_value = 1101
        project_phase.phase_limit = 1001
        project_phase.valid?
        expect(project_phase.errors[:phase_value]).to eq ["must be less than or equal to 1100.0"]
        expect(project_phase.errors[:phase_limit]).to eq ["must be less than or equal to 1000.0"]
      end

      context 'Siteあり' do
        before do
          FactoryBot.create(:project_phase_site, project_phase: project_phase,
            phase_limit: 200, site_limit: 100)
        end

        it 'PhaseLimitがSiteの合計以上であること' do
          project_phase.phase_value = 1000
          project_phase.phase_limit = 199
          project_phase.valid?
          expect(project_phase.errors[:phase_limit]).to eq ["must be greater than or equal to 200.0"]
        end
      end
    end
  end
end
