# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReduceSiteLimit, type: :model do
  describe '#call' do
    let(:contractor) { FactoryBot.create(:contractor, pool_amount: 0) }
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:site) { Site.first }
    let(:installment) { Installment.first }

    before do
      FactoryBot.create(:business_day, business_ymd: '20210616')

      site = FactoryBot.create(:site, site_credit_limit: 300)
      order = FactoryBot.create(:order, :cpac, site: site)
      installment = FactoryBot.create(:installment, order: order)
    end

    describe 'reduced_site_limit' do
      it '正しいこと' do
        reduce_amount = 100
        ReduceSiteLimit.new.call(installment, reduce_amount)

        expect(site.site_credit_limit).to eq 200
        expect(installment.reduced_site_limit).to eq reduce_amount
      end

      describe '元本の消し込みがSiteLimitを超える場合' do
        it 'Site Limitを減らした分だけが記録されること' do
          reduce_amount = 301
          ReduceSiteLimit.new.call(installment, reduce_amount)

          expect(site.site_credit_limit).to eq 0
          expect(installment.reduced_site_limit).to eq 300
        end
      end
    end
  end
end
