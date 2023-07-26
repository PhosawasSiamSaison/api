# frozen_string_literal: true
# == Schema Information
#
# Table name: sites
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)
#  dealer_id            :bigint(8)        not null
#  is_project           :boolean          default(FALSE), not null
#  site_code            :string(15)       not null
#  site_name            :string(255)      not null
#  site_credit_limit    :decimal(13, 2)   not null
#  closed               :boolean          default(FALSE), not null
#  create_user_id       :integer          not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

require 'rails_helper'

RSpec.describe Site, type: :model do
  let(:contractor) { FactoryBot.create(:contractor) }

  describe '#remaining_principal' do
    let(:site) { FactoryBot.create(:site)}

    describe 'InputDateあり' do
      before do
        order = FactoryBot.create(:order, :inputed_date, site: site, contractor: contractor)
        FactoryBot.create(:installment, order: order, principal: 100, paid_principal: 60)
      end

      it '値が正しく取得できること' do
        expect(site.remaining_principal).to eq 40
      end
    end

    describe 'InputDateなし' do
      before do
        order = FactoryBot.create(:order, site: site, contractor: contractor)
        FactoryBot.create(:installment, order: order, principal: 100, paid_principal: 60)
      end

      it '値が正しく取得できること' do
        expect(site.remaining_principal).to eq 40
      end
    end
  end

  describe '#search' do
    before do
      FactoryBot.create(:site, contractor: contractor)
      FactoryBot.create(:site, :closed, contractor: contractor)
      FactoryBot.create(:site)
    end

    it '正しいContractorからSiteが取得できること' do
      params = {
        contractor_id: contractor.id,
        search: {
          include_closed: true
        }
      }

      sites, total_count = Site.search(params)

      expect(sites.count).to eq 2
    end

    it 'Include Closedの判定が正しくされること' do
      params = {
        contractor_id: contractor.id,
        search: {
          include_closed: false
        }
      }

      sites, total_count = Site.search(params)

      expect(sites.count).to eq 1
      expect(sites.first.closed?).to eq false
    end

    it 'ページングがされること' do
      params = {
        contractor_id: contractor.id,
        search: {
          include_closed: true
        },
        page: 1,
        per_page: 1
      }

      sites, total_count = Site.search(params)

      expect(sites.count).to eq 1
      expect(total_count).to eq 2
    end
  end
end
