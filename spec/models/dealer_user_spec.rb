# frozen_string_literal: true
# == Schema Information
#
# Table name: dealer_users
#
#  id                   :bigint(8)        not null, primary key
#  dealer_id            :integer          not null
#  user_type            :integer          not null
#  user_name            :string(20)
#  full_name            :string(40)       not null
#  mobile_number        :string(11)
#  email                :string(200)
#  agreed_at            :datetime
#  password_digest      :string(255)      not null
#  temp_password        :string(255)
#  create_user_type     :string(255)
#  create_user_id       :integer          not null
#  update_user_type     :string(255)
#  update_user_id       :integer          not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

require 'rails_helper'

RSpec.describe DealerUser, type: :model do
  let(:dealer_user) { FactoryBot.create(:dealer_user) }

  describe '重複エラーチェック' do
    it 'user_nameの重複でエラーに なる こと' do
      dealer_user2 = FactoryBot.build(:dealer_user, user_name: dealer_user.user_name)
      dealer_user2.valid?
      expect(dealer_user2.errors.messages[:user_name]).to eq ["has already been taken"]
    end

    it 'mobile_numberの重複でエラーに なる こと' do
      dealer_user2 = FactoryBot.build(:dealer_user, mobile_number: dealer_user.mobile_number)
      dealer_user2.valid?
      expect(dealer_user2.errors.messages[:mobile_number]).to eq ["has already been taken"]
    end

    it '削除したdealer_userのuser_nameの重複でエラーに ならない こと' do
      dealer_user2 = FactoryBot.build(:dealer_user, user_name: dealer_user.user_name)
      dealer_user.update!(deleted: true)
      dealer_user2.valid?
      expect(dealer_user2.errors.messages[:user_name]).to eq []
    end

    it '削除したdealer_userのmobile_numberの重複でエラーに ならない こと' do
      dealer_user2 = FactoryBot.build(:dealer_user, mobile_number: dealer_user.mobile_number)
      dealer_user.update!(deleted: true)
      dealer_user2.valid?
      expect(dealer_user2.errors.messages[:mobile_number]).to eq []
    end

    it 'dealer_userのnilのmobile_numberが重複エラーに ならない こと' do
      dealer_user.update!(mobile_number: nil)
      dealer_user2 = FactoryBot.create(:dealer_user, mobile_number: nil)
      dealer_user2.valid?
      expect(dealer_user2.errors.messages[:mobile_number]).to eq []
    end

    it 'emailが必須でないこと' do
      expect(dealer_user.update(email: nil)).to be_truthy
    end
  end
end
