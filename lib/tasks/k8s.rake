# frozen_string_literal: true

require "k8s_configuration_exporter"

namespace :k8s do
  desc "usage: bundle exec rails k8s:export_configuration IMAGE=<docker_image_ref> [ENABLE_SYNC=true]"
  task export_configuration: :environment do
    image = ENV["IMAGE"]
    enable_sync = ENV["ENABLE_SYNC"] == "true"

    raise "You must specify a docker image, usage: bundle exec rails decidim:k8s:export_configuration IMAGE=<image_ref> [ENABLE_SYNC=true]" if image.blank?

    K8sConfigurationExporter.export!(image, enable_sync)
  end
end
