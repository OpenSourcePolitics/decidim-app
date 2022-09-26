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

  describe "GET decidim.root_pqth" do
    let(:headers) { { "REMOTE_ADDR" => "1.2.3.4", "decidim.current_organization" => organization } }
    it "successful for 100 requests, then blocks the user nicely" do
      100.times do
        get decidim.root_path, params: {}, headers: headers
        expect(response).to have_http_status(:ok)
      end

      get decidim.root_path, params: {}, headers: headers
      expect(response.body).to include("Retry later")
      expect(response).to have_http_status(:too_many_requests)

      travel_to(10.minutes.from_now) do
        get decidim.root_path, params: {}, headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
