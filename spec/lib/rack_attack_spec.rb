# frozen_string_literal: true

require "spec_helper"

describe Rack::Attack, type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:organization) { create(:organization) }

  before do
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  after do
    Rack::Attack.enabled = false
  end

  describe "GET decidim.root_path" do
    let(:headers) { { "REMOTE_ADDR" => "1.2.3.4", "decidim.current_organization" => organization } }

    it "successful for 100 requests, then blocks the user nicely" do
      100.times do
        get decidim.root_path, params: {}, headers: headers
        expect(response).to have_http_status(:ok)
      end

      get decidim.root_path, params: {}, headers: headers
      expect(response.body).to include("Your connection have been slowed because server received too many requests.")
      expect(response).to have_http_status(:too_many_requests)

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
      expect(response.body).not_to include("Your connection have been slowed because server received too many requests.")
      expect(response).not_to have_http_status(:too_many_requests)

      travel_to(1.minute.from_now) do
        get decidim.root_path, params: {}, headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
