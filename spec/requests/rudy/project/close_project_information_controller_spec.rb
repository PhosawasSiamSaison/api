require 'rails_helper'

RSpec.describe Rudy::Project::CloseProjectInformationController, type: :request do
  before do
    FactoryBot.create(:business_day, business_ymd: '20190101')
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)
  end

  describe "POST #call" do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:dealer) { FactoryBot.create(:dealer, :cpac)}
    let(:site) { FactoryBot.create(:site, contractor: contractor, is_project: true) }

    before do
      FactoryBot.create(:eligibility, contractor: contractor, limit_amount: 1000)
      FactoryBot.create(:contractor_user, contractor: contractor)
    end

    it "SMSが送信されること" do
      params = {
        tax_id: contractor.tax_id,
        project_code: site.site_code
      }

      post rudy_close_project_information_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'

      site = Site.first

      expect(site.closed?).to eq true
    end
  end
end
