# frozen_string_literal: true

require "spec_helper"

describe DecidimApp::RackAttack, type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:organization) { create(:organization) }

  describe "#rack_enabled?" do
    it "returns false" do
      expect(described_class).not_to be_rack_enabled
    end

    context "when ENV variable is set to '1'" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :rack_attack, :enabled).and_return("1")
      end

      it "returns true" do
        expect(described_class).to be_rack_enabled
      end
    end

    context "when ENV variable is set to '0'" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :rack_attack, :enabled).and_return("0")
      end

      it "returns false" do
        expect(described_class).not_to be_rack_enabled
      end
    end

    context "when rails env is production" do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it "returns true" do
        expect(described_class).to be_rack_enabled
      end

      context "when ENV variable is set to '1'" do
        before do
          allow(Rails.application.secrets).to receive(:dig).with(:decidim, :rack_attack, :enabled).and_return("1")
        end

        it "returns true" do
          expect(described_class).to be_rack_enabled
        end
      end

      context "when ENV variable is set to '0'" do
        before do
          allow(Rails.application.secrets).to receive(:dig).with(:decidim, :rack_attack, :enabled).and_return("0")
        end

        it "returns false" do
          expect(described_class).not_to be_rack_enabled
        end
      end
    end
  end

  describe "#apply_configuration" do
    before do
      described_class.apply_configuration
      Rack::Attack.reset!
    end

    describe "Throttling" do
      let(:headers) { { "REMOTE_ADDR" => "1.2.3.4", "decidim.current_organization" => organization } }

      it "successful for 100 requests, then blocks the user" do
        100.times do
          get decidim.root_path, params: {}, headers: headers
          expect(response).to have_http_status(:ok)
        end

        get decidim.root_path, params: {}, headers: headers
        expect(response).to have_http_status(:too_many_requests)
        expect(response.body).to include("Your connection has been slowed because server received too many requests.")

        travel_to(1.minute.from_now) do
          get decidim.root_path, params: {}, headers: headers
          expect(response).to have_http_status(:ok)
        end
      end

      it "successful for 99 requests" do
        99.times do
          get decidim.root_path, params: {}, headers: headers
          expect(response).to have_http_status(:ok)
        end

        get decidim.root_path, params: {}, headers: headers
        expect(response.body).not_to include("Your connection has been slowed because server received too many requests.")
        expect(response).not_to have_http_status(:too_many_requests)

        travel_to(1.minute.from_now) do
          get decidim.root_path, params: {}, headers: headers
          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe "Fail2Ban" do
      let(:headers) { { "REMOTE_ADDR" => "1.2.3.4", "decidim.current_organization" => organization } }

      %w(/etc/passwd /wp-admin/index.php /wp-login/index.php SELECT CONCAT /.git/config).each do |path|
        it "blocks user for specific request : '#{path}'" do
          get "#{decidim.root_path}#{path}", params: {}, headers: headers
          expect(response).to have_http_status(:forbidden)

          get decidim.root_path, params: {}, headers: headers
          expect(response).to have_http_status(:forbidden)

          travel_to(61.minutes.from_now) do
            get decidim.root_path, params: {}, headers: headers
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end
  end
end
