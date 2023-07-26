# frozen_string_literal: true
# == Schema Information
#
# Table name: jv_users
#
#  id                   :bigint(8)        not null, primary key
#  user_type            :integer          not null
#  system_admin         :boolean          default(FALSE), not null
#  user_name            :string(20)
#  full_name            :string(40)       not null
#  mobile_number        :string(11)
#  email                :string(200)
#  password_digest      :string(255)      not null
#  temp_password        :string(16)
#  create_user_id       :integer
#  update_user_id       :integer
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

require 'rails_helper'

RSpec.describe JvUser, type: :model do
  let(:jv_user) { FactoryBot.create(:jv_user) }

  describe '#save_auth_token' do
    it 'auth_tokenが保存されること' do
      jv_user.save_auth_token("hoge")

      expect(jv_user.auth_tokens.count).to eq 1
      expect(jv_user.auth_tokens.first.token).to eq "hoge"
    end
  end

  describe '#delete_with_auth_tokens' do
    before do
      jv_user.save_auth_token("hoge")
      jv_user.save_auth_token("fuga")
    end

    it 'jv_userがdeletedになり、auth_tokensが削除されること' do
      id = jv_user.id
      jv_user.delete_with_auth_tokens

      expect(JvUser.unscoped.find(id).deleted).to eq 1
      expect(AuthToken.where(tokenable_id: id)).to eq []
    end
  end

  describe '重複エラーチェック' do
    it 'user_nameの重複でエラーに なる こと' do
      jv_user2 = FactoryBot.build(:jv_user, user_name: jv_user.user_name)
      jv_user2.valid?
      expect(jv_user2.errors.messages[:user_name]).to eq ["has already been taken"]
    end

    it '削除したjv_userのuser_nameの重複でエラーに ならない こと' do
      jv_user2 = FactoryBot.build(:jv_user, user_name: jv_user.user_name)
      jv_user.update!(deleted: true)
      jv_user2.valid?
      expect(jv_user2.errors.messages[:user_name]).to eq []
    end
  end

  it 'emailが必須でないこと' do
    expect(jv_user.update(email: nil)).to be_truthy
  end
end
