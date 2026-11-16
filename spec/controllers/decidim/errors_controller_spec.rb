# frozen_string_literal: true

require "spec_helper"

describe Decidim::ErrorsController do
  routes { Decidim::Core::Engine.routes }

  let(:organization) { create(:organization) }
  let(:origin) { "/send-me-somewhere" }
  let!(:config) do
    create(:awesome_config, organization:, var: :custom_redirects, value: {
             origin => { destination:, active: true, pass_query: false }
           })
  end

  before do
    request.env["decidim.current_organization"] = organization
    request.env["ORIGINAL_FULLPATH"] = origin
  end

  context "when the custom redirect points to another host" do
    let(:destination) { "https://example.org/elsewhere" }

    it "redirects to the external destination" do
      get :not_found

      expect(response).to redirect_to(destination)
    end
  end

  context "when the custom redirect points to a local path" do
    let(:destination) { "/canary-islands" }

    it "redirects to the local destination" do
      get :not_found

      expect(response).to redirect_to(destination)
    end
  end
end
