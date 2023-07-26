# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthContractorUser, type: :model do
  let(:contractor_user) { FactoryBot.create(:contractor_user, password: '123456') }

  it 'jv-serviceで認証が成功すること' do
    result = AuthContractorUser.new(contractor_user, '123456').call
    expect(result).to eq true
  end

  it 'RUDYで認証が成功すること' do
    result = AuthContractorUser.new(contractor_user, '200').call
    expect(result).to eq true
  end

  it 'jv-serviceとRUDYで認証が失敗すること' do
    result = AuthContractorUser.new(contractor_user, '404').call
    expect(result).to eq false
  end
end
