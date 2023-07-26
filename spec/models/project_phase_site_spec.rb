# == Schema Information
#
# Table name: project_phase_sites
#
#  id                   :bigint(8)        not null, primary key
#  project_phase_id     :bigint(8)        not null
#  contractor_id        :bigint(8)        not null
#  site_code            :string(255)      not null
#  site_name            :string(255)      not null
#  phase_limit          :decimal(10, 2)   not null
#  site_limit           :decimal(10, 2)   default(0.0), not null
#  paid_total_amount    :decimal(10, 2)   default(0.0)
#  refund_amount        :decimal(10, 2)   default(0.0)
#  status               :integer          default("opened"), not null
#  create_user_id       :bigint(8)        not null
#  update_user_id       :bigint(8)        not null
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

require 'rails_helper'

RSpec.describe ProjectPhaseSite, type: :model do
  let(:project_phase_site) { FactoryBot.create(:project_phase_site) } 

  describe "validates" do
    describe "site_code" do
      describe "nil" do
        before do
          project_phase_site.site_code = nil
        end
      
        it "エラーになること" do
          project_phase_site.valid?
          expect(project_phase_site.errors.messages[:site_code]).to eq ["can't be blank"]  
        end
      end
    end

    describe "site_name" do
      describe "nil" do
        before do
          project_phase_site.site_name = nil
        end
      
        it "エラーになること" do
          project_phase_site.valid?
          expect(project_phase_site.errors.messages[:site_name]).to eq ["can't be blank"]  
        end
      end
    end

    describe '比較' do
      it 'phase_limit >= site_limit' do
        project_phase_site.phase_limit = 100
        project_phase_site.site_limit = 101

        project_phase_site.valid?(:update_site_limit)
        expect(project_phase_site.errors[:phase_limit]).to eq ["must be greater than or equal to 101.0"]
      end

      it 'site.phase_limitがphase.phase_limitを超えないこと' do
        project_phase_site.project_phase.phase_limit = 200
        project_phase_site.phase_limit = 201
        project_phase_site.site_limit = 50

        project_phase_site.valid?(:update_site_limit)
        expect(project_phase_site.errors[:phase_limit]).to eq ["must be less than or equal to 200.0"]
      end
    end
  end
end
