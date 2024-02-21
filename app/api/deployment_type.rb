# frozen_string_literal: true

require "uri"
require "net/http"

class DeploymentType < Decidim::Api::Types::BaseObject
  description "Deployment's related properties."

  field :decidim_version, GraphQL::Types::String, "The Decidim version", null: false

  def decidim_version
    Decidim.version
  end
end
