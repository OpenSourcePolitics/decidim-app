# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"

describe "DeploymentType" do
  include_context "with a graphql class type"
  let(:schema) { Decidim::Api::Schema }
  let(:query) do
    %(
      query {
          deployment {
            decidim_version
          }
      }
    )
  end

  describe "valid query" do
    it "executes sucessfully" do
      expect { response }.not_to raise_error
    end

    it "has deployment" do
      expect(response["deployment"]).to eq({
                                             "decidim_version" => Decidim.version
                                           })
    end
  end
end
