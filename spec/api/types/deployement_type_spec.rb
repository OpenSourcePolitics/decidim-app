# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"

describe "DeploymentType" do
  include_context "with a graphql class type"
  let(:schema) { Decidim::Api::Schema }

  let(:locale) { "en" }

  let(:query) do
    %(
      query {
          deployment {
            registry
            image
            tag
            decidimVersion
          }
      }
    )
  end

  describe "deployment" do
    before do
      allow(Decidim).to receive(:version).and_return("0.30.0")
      allow(ENV).to receive(:fetch).with("DOCKER_IMAGE", "rg.fr-par.scw.cloud/decidim-app/decidim-app").and_return("registry.example.org/decidim-app/decidim-app")
      allow(ENV).to receive(:fetch).with("DOCKER_IMAGE_NAME", "decidim-app").and_return("decidim-example")
      allow(ENV).to receive(:fetch).with("DOCKER_IMAGE_TAG", "latest").and_return("3.0.0")
    end

    it "executes sucessfully" do
      expect { response }.not_to raise_error
    end

    it "has deployment" do
      expect(response["deployment"]).to eq({
                                             "tag" => "3.0.0",
                                             "registry" => "registry.example.org",
                                             "image" => "decidim-example",
                                             "decidimVersion" => "0.30.0"
                                           })
    end
  end

  context "when the registry is not set" do
    it "returns default value" do
      expect(response["deployment"]["registry"]).to eq("rg.fr-par.scw.cloud")
    end
  end

  context "when the image is not set" do
    it "returns default value" do
      expect(response["deployment"]["image"]).to eq("decidim-app")
    end
  end

  context "when the tag is not set" do
    it "returns default value" do
      expect(response["deployment"]["tag"]).to eq("latest")
    end
  end
end
