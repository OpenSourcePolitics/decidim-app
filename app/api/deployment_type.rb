# frozen_string_literal: true
require "uri"
require "net/http"

class DeploymentType < Decidim::Api::Types::BaseObject
  description "Decidim's framework-related properties."

  field :current_commit, GraphQL::Types::String, "The current decidim's version of this deployment.", null: false
  field :branch, GraphQL::Types::String, "The current decidim's version of this deployment.", null: false
  field :version, GraphQL::Types::String, "The current decidim's version of this deployment.", null: false
  field :up_to_date, GraphQL::Types::Boolean, "The current decidim's version of this deployment.", null: false
  field :latest_commit, GraphQL::Types::String, "The current decidim's version of this deployment.", null: false

  def current_commit
    `git rev-parse HEAD`.strip
  end

  def version
    Decidim.version
  end
  
  def branch
    `git rev-parse --abbrev-ref HEAD`.strip
  end

  def up_to_date
    current_commit == latest_commit
  end

  def latest_commit
    url = URI("https://api.github.com/repos/OpenSourcePolitics/decidim-app/commits/master")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)

    response = https.request(request)
    JSON.parse(response.read_body)["sha"]
  end
end