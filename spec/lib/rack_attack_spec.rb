# frozen_string_literal: true

require "spec_helper"

describe "Rack::Attack", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:organization) { create(:organization) }

  before do
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  after do
    Rack::Attack.enabled = false
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
      99.times do |_|
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
