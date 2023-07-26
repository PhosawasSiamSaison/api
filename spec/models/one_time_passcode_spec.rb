# == Schema Information
#
# Table name: one_time_passcodes
#
#  id           :bigint(8)        not null, primary key
#  token        :string(30)       not null
#  passcode     :string(255)      not null
#  expires_at   :datetime         not null
#  deleted      :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  lock_version :integer          default(0)
#

require 'rails_helper'

RSpec.describe OneTimePasscode, type: :model do
  let(:one_time_passcode) { OneTimePasscode.new(params) }
  let(:params) { { token: token, passcode: passcode, expires_at: expires_at } }
  let(:token) { SecureRandom.urlsafe_base64 }
  let(:passcode) { '012345' }
  let(:expires_at) { Time.zone.now + 15.minutes }

  describe 'validation' do
    context 'token is nil' do
      let(:token) { nil }
      it "is invalid without a token" do
        expect(one_time_passcode.valid?).to eq false
        expect(one_time_passcode.errors.messages[:token]).to include("can't be blank")
      end
    end

    context 'when passcode is nil' do
      let(:passcode) { nil }
      it "is invalid without a passcode" do
        expect(one_time_passcode.valid?).to eq false
        expect(one_time_passcode.errors.messages[:passcode]).to include("can't be blank")
      end
    end

    context 'when expires_at is nil' do
      let(:expires_at) { nil }
      it "is invalid without a expires_at" do
        expect(one_time_passcode.valid?).to eq false
        expect(one_time_passcode.errors.messages[:expires_at]).to include("can't be blank")
      end
    end
  end

  describe '#expired?' do
    before do
      one_time_passcode.save!
    end

    context 'when not expired' do
      let(:expires_at) { Time.zone.now + 1.minutes }
      it { expect(one_time_passcode.expired?).to eq false }
    end

    context 'when expired' do
      let(:expires_at) { Time.zone.now - 1.second }
      it { expect(one_time_passcode.expired?).to eq true }
    end
  end
 end
