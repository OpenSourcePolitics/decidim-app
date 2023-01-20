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
            version
            branch
            upToDate
            currentCommit
            latestCommit
            locallyModified
          }
      }
    )
  end

  let(:github_response) do
    JSON.dump(sha: "220fd7b6f8701816c60c0610d5a62a59b962b231")
  end

  let(:branch) { "master" }
  let(:repo_name) { "repo_name" }

  before do
    stub_request(:get, "https://api.github.com/repos/repo_name/commits/master").with(
      headers: {
        "Accept" => "*/*",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Host" => "api.github.com",
        "User-Agent" => "Ruby"
      }
    ).to_return(status: 200, body: github_response, headers: {})
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(DeploymentType).to receive(:`).with("git ls-remote --get-url").and_return(repo_name)
    allow_any_instance_of(DeploymentType).to receive(:`).with("git rev-parse HEAD").and_return("220fd7b6f8701816c60c0610d5a62a59b962b231")
    allow_any_instance_of(DeploymentType).to receive(:`).with("git rev-parse --abbrev-ref HEAD").and_return("master")
    allow_any_instance_of(DeploymentType).to receive(:`).with("git status --porcelain").and_return("")
    # rubocop:enable RSpec/AnyInstance
  end

  describe "valid query" do
    it "executes sucessfully" do
      expect { response }.not_to raise_error
    end

    it "has deployment" do
      expect(response["deployment"]).to eq({
                                             "version" => Decidim::Core.version,
                                             "branch" => "master",
                                             "upToDate" => true,
                                             "currentCommit" => "220fd7b6f8701816c60c0610d5a62a59b962b231",
                                             "latestCommit" => "220fd7b6f8701816c60c0610d5a62a59b962b231",
                                             "locallyModified" => false
                                           })
    end

    context "when partial_url ends with .git" do
      let(:repo_name) { "repo_name.git" }

      it "executes sucessfully" do
        expect { response }.not_to raise_error
      end
    end
  end
end
