# == Schema Information
#
# Table name: project_documents
#
#  id                   :bigint(8)        not null, primary key
#  project_id           :bigint(8)        not null
#  file_type            :integer          not null
#  ss_staff_only        :boolean          default(FALSE)
#  file_name            :string(100)      not null
#  comment              :text(65535)
#  create_user_id       :bigint(8)        not null
#  update_user_id       :bigint(8)        not null
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

require 'rails_helper'

RSpec.describe ProjectDocument, type: :model do
  let(:project_document) { FactoryBot.create(:project_document) } 
  
  describe "validates" do
    describe "file_type" do
      describe "nil" do
        before do
            project_document.file_type = nil
        end

        it "エラーになること" do
            project_document.valid?
            expect(project_document.errors.messages[:file_type]).to eq ["can't be blank"] 
        end
      end
    end

    describe "file_name" do
      describe "nil" do
        before do
            project_document.file_name = nil
        end

        it "エラーになること" do
            project_document.valid?
            expect(project_document.errors.messages[:file_name]).to eq ["can't be blank"] 
        end
      end
    end
  end
  
end
