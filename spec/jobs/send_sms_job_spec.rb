require 'rails_helper'

RSpec.describe SendSmsJob, type: :job do
  describe "#perform" do
    ActiveJob::Base.queue_adapter = :test
    it "JobがEnqueueされること" do
      expect{ SendSmsJob.perform_later }.to have_enqueued_job(SendSmsJob)
    end
  end
end
