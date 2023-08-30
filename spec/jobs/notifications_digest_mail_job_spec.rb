# frozen_string_literal: true

require "spec_helper"

describe NotificationsDigestMailJob, type: :job do
  describe "#perform" do
    [:daily, :weekly].each do |frequency|
      it "calls notifications digest with #{frequency}" do
        expect(Decidim::NotificationsDigest).to receive(:notifications_digest).with(frequency)

        subject.perform(frequency)
      end
    end
  end
end
