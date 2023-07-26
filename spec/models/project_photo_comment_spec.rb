# == Schema Information
#
# Table name: project_photo_comments
#
#  id                   :bigint(8)        not null, primary key
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

RSpec.describe ProjectPhotoComment, type: :model do
  let(:project_photo_comment) { FactoryBot.create(:project_photo_comment) }

  describe "validates" do
    describe "file_name" do
      describe "nil" do
        before do
          project_photo_comment.file_name = nil
        end

        it "エラーになること" do
          project_photo_comment.valid?
          expect(project_photo_comment.errors.messages[:file_name]).to eq ["can't be blank"]
        end
      end

      describe "empty" do
        before do
          project_photo_comment.file_name = ''
        end

        it "エラーになること" do
          project_photo_comment.valid?
          expect(project_photo_comment.errors.messages[:file_name]).to eq ["can't be blank"]
        end
      end
    end

    describe "comment" do
      describe "nil" do
        before do
          project_photo_comment.comment = nil
        end

        it "エラーになること" do
          project_photo_comment.valid?
          expect(project_photo_comment.errors.messages[:comment]).to eq ["can't be blank"]
        end
      end

      describe "empty" do
        before do
          project_photo_comment.comment = ''
        end

        it "エラーになること" do
          project_photo_comment.valid?
          expect(project_photo_comment.errors.messages[:comment]).to eq ["can't be blank"]
        end
      end
    end
  end
end
