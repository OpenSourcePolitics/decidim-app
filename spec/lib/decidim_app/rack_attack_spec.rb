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

  describe "#enable_rack_attack!" do
    before do
      described_class.enable_rack_attack!
    end

    it "enables Rack::Attack" do
      expect(Rack::Attack.enabled).to be_truthy
    end
  end

  describe "#disable_rack_attack!" do
    before do
      described_class.disable_rack_attack!
    end

    it "enables Rack::Attack" do
      expect(Rack::Attack.enabled).to be_falsey
    end
  end

  describe "#deactivate_decidim_throttling!" do
    before do
      described_class.deactivate_decidim_throttling!
    end

    it "deactivates Decidim throttling" do
      # Decidim throttling is deactivated by default in rails env test
      # https://github.com/decidim/decidim/blob/release/0.27-stable/decidim-core/config/initializers/rack_attack.rb#L19
      expect(Rack::Attack.throttles.keys.join).to include("limit confirmations attempts per code")
    end
  end

  describe "#apply_configuration" do
    describe "Throttling" do
      let(:headers) { { "REMOTE_ADDR" => "1.2.3.4", "decidim.current_organization" => organization } }
      let(:rack_max_requests) { 15 }

      before do
        allow(Rails.application.secrets).to receive(:dig).with(any_args).and_call_original
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :rack_attack, :throttle, :max_requests).and_return(rack_max_requests)
        described_class.apply_configuration
        Rack::Attack.reset!
        described_class.enable_rack_attack!
      end

      it "defines default period and max_requests" do
        expect(DecidimApp::RackAttack::Throttling.max_requests).to eq(rack_max_requests)
        expect(DecidimApp::RackAttack::Throttling.period).to eq(60)
      end

      it "successful for 15 requests, then blocks the user" do
        rack_max_requests.times do
          get decidim.root_path, params: {}, headers: headers
          expect(response).to have_http_status(:ok)
          expect(response.body).not_to include("Your connection has been slowed because server received too many requests.")
        end

        get decidim.root_path, params: {}, headers: headers
        expect(response).to have_http_status(:too_many_requests)
        expect(response.body).to include("Your connection has been slowed because server received too many requests.")

        travel_to(1.minute.from_now) do
          get decidim.root_path, params: {}, headers: headers
          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe "Fail2Ban" do
      let(:headers) { { "REMOTE_ADDR" => "1.2.3.4", "decidim.current_organization" => organization } }

      before do
        described_class.apply_configuration
        Rack::Attack.reset!
        described_class.enable_rack_attack!
      end

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