# frozen_string_literal: true

require "spec_helper"
require "decidim/notifications_digest"

describe Decidim::NotificationsDigest do
  describe "#notifications_digest" do
    subject { described_class.notifications_digest(frequency) }

    let(:frequency) { :daily }
    let!(:users_daily) { create_list :user, 4, notifications_sending_frequency: :daily }
    let!(:users_weekly) { create_list :user, 2, notifications_sending_frequency: :weekly }

    before do
      allow(Decidim::EmailNotificationsDigestGeneratorJob).to receive(:perform_later).and_return(true)
    end

    it "executes DigestGeneratorJob on daily users" do
      subject

      expect(Decidim::EmailNotificationsDigestGeneratorJob).to have_received(:perform_later).exactly(4)
    end

    context "and frequency is weekly" do
      let(:frequency) { :weekly }

      it "executes DigestGeneratorJob on weekly users" do
        subject

        expect(Decidim::EmailNotificationsDigestGeneratorJob).to have_received(:perform_later).exactly(2)
      end
    end

    context "and frequency is not in list" do
      let(:frequency) { :unknown }

      it "executes DigestGeneratorJob on weekly users" do
        subject

        expect(Decidim::EmailNotificationsDigestGeneratorJob).not_to have_received(:perform_later)
      end
    end
  end
end
