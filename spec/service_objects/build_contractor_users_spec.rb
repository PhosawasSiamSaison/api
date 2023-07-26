# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BuildContractorUsers, type: :model do
  let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:jv_user) { auth_token.tokenable }
  let(:contractor) { FactoryBot.create(:contractor) }

  context 'Same as なし' do
    before do
      contractor.update!(
        authorized_person_same_as_owner: false,
        contact_person_same_as_owner: false,
        contact_person_same_as_authorized_person: false)
    end

    it 'owner, authorized の2user が取得できること' do
      contractor_users = BuildContractorUsers.new(contractor, jv_user).call
      expect(contractor_users.count).to eq 2

      full_names = contractor_users.map(&:full_name)
      expect(full_names.include?(contractor.th_owner_name)).to eq true
      expect(full_names.include?(contractor.authorized_person_name)).to eq true
      expect(full_names.include?(contractor.contact_person_name)).to eq false
    end
  end

  context 'authorized_person_same_as_owner のチェックあり' do
    before do
      contractor.update!(
        authorized_person_same_as_owner: true,
        contact_person_same_as_owner: false,
        contact_person_same_as_authorized_person: false)
    end

    it 'owner の1user が取得できること' do
      contractor_users = BuildContractorUsers.new(contractor, jv_user).call
      expect(contractor_users.count).to eq 1

      full_names = contractor_users.map(&:full_name)
      expect(full_names.include?(contractor.th_owner_name)).to eq true
      expect(full_names.include?(contractor.authorized_person_name)).to eq false
      expect(full_names.include?(contractor.contact_person_name)).to eq false
    end
  end

  context 'contact_person_same_as_owner のチェックあり' do
    before do
      contractor.update!(
        authorized_person_same_as_owner: false,
        contact_person_same_as_owner: true,
        contact_person_same_as_authorized_person: false)
    end

    it 'owner, authorized の2user が取得できること' do
      contractor_users = BuildContractorUsers.new(contractor, jv_user).call
      expect(contractor_users.count).to eq 2

      full_names = contractor_users.map(&:full_name)
      expect(full_names.include?(contractor.th_owner_name)).to eq true
      expect(full_names.include?(contractor.authorized_person_name)).to eq true
      expect(full_names.include?(contractor.contact_person_name)).to eq false
    end
  end

  context 'contact_person_same_as_authorized_person のチェックあり' do
    before do
      contractor.update!(
        authorized_person_same_as_owner: false,
        contact_person_same_as_owner: false,
        contact_person_same_as_authorized_person: true)
    end

    it 'owner, authorized 2user が取得できること' do
      contractor_users = BuildContractorUsers.new(contractor, jv_user).call
      expect(contractor_users.count).to eq 2

      full_names = contractor_users.map(&:full_name)
      expect(full_names.include?(contractor.th_owner_name)).to eq true
      expect(full_names.include?(contractor.authorized_person_name)).to eq true
      expect(full_names.include?(contractor.contact_person_name)).to eq false
    end
  end

  context 'Ownerのみ' do
    before do
      contractor.update!(
        authorized_person_same_as_owner: true,
        contact_person_same_as_owner: true,
        contact_person_same_as_authorized_person: false)
    end

    it 'owner 1user が取得できること' do
      contractor_users = BuildContractorUsers.new(contractor, jv_user).call
      expect(contractor_users.count).to eq 1

      full_names = contractor_users.map(&:full_name)
      expect(full_names.include?(contractor.th_owner_name)).to eq true
      expect(full_names.include?(contractor.authorized_person_name)).to eq false
      expect(full_names.include?(contractor.contact_person_name)).to eq false
    end
  end
end
