# frozen_string_literal: true

require "uri"
require "net/http"

class DeploymentType < Decidim::Api::Types::BaseObject
  description "Deployment's related properties."

  field :registry, GraphQL::Types::String, "The image's docker registry", null: false
  field :image, GraphQL::Types::String, "The docker image name for this deployment", null: false
  field :tag, GraphQL::Types::String, "The docker image tag for this deployment", null: false
  field :decidim_version, GraphQL::Types::String, "The current decidim's version of this deployment.", null: false

  def registry
    # default value defined in Dockerfile: DOCKER_IMAGE=${DOCKER_IMAGE:-rg.fr-par.scw.cloud/decidim-app/decidim-app}
    full_image = ENV.fetch("DOCKER_IMAGE", "rg.fr-par.scw.cloud/decidim-app/decidim-app")

    full_image.split("/")&.first
  end

  def image
    # default value defined in Dockerfile: DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-decidim-app}
    ENV.fetch("DOCKER_IMAGE_NAME", "decidim-app")
  end

  def tag
    # default value defined in Dockerfile: DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG:-latest} \
    ENV.fetch("DOCKER_IMAGE_TAG", "latest")
  end

  def decidim_version
    Decidim.version
  end
end
