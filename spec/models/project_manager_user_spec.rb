# == Schema Information
#
# Table name: project_manager_users
#
#  id                   :bigint(8)        not null, primary key
#  project_manager_id   :integer          not null
#  user_type            :integer          not null
#  user_name            :string(20)
#  full_name            :string(40)       not null
#  mobile_number        :string(11)
#  email                :string(200)
#  password_digest      :string(255)      not null
#  temp_password        :string(16)
#  create_user_id       :bigint(8)        not null
#  update_user_id       :bigint(8)        not null
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

require 'rails_helper'

RSpec.describe ProjectManagerUser, type: :model do
  let(:project_manager_user) { FactoryBot.create(:project_manager_user) }
  
  describe "validates" do
    describe "user_name" do
      describe "nil" do
        before do
          project_manager_user.user_name = nil
        end
      
        it "エラーになること" do
          project_manager_user.valid?
          expect(project_manager_user.errors.messages[:user_name]).to eq ["can't be blank"]  
        end
      end
    end

    describe "full_name" do
      describe "nil" do
        before do
          project_manager_user.full_name = nil
        end
      
        it "エラーになること" do
          project_manager_user.valid?
          expect(project_manager_user.errors.messages[:full_name]).to eq ["can't be blank"]  
        end
      end
    end
  end
  
end
