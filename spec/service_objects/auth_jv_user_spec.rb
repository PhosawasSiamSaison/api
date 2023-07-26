# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthJvUser, type: :model do
  describe 'Auth Jv User' do
    it '成功' do
      jv_user = FactoryBot.create(:jv_user,
                        user_name: "test_user",
                        password_digest: BCrypt::Password.create("password")
      )

      expect(
        AuthJvUser.new(jv_user, "password").call
      ).to eq true
    end

    it 'パスワード間違い' do
      jv_user = FactoryBot.create(:jv_user,
                        user_name: "test_user",
                        password_digest: BCrypt::Password.create('password')
      )

      expect(
        AuthJvUser.new(jv_user, "invalid-password").call
      ).to eq false
    end

    it '存在しないユーザー' do
      expect(
        AuthJvUser.new(nil, "password").call
      ).to eq false
    end
  end
end
