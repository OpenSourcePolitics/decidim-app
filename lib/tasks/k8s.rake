# frozen_string_literal: true

require "k8s_configuration_exporter"

namespace :k8s do
  desc "usage: bundle exec rails k8s:dump_db"
  task dump_db: :environment do
    K8sConfigurationExporter.dump_db
  end

  desc "usage: bundle exec rails k8s:export_configuration IMAGE=<docker_image_ref>"
  task export_configuration: :environment do
    image = ENV["IMAGE"]
    raise "You must specify a docker image, usage: bundle exec rails k8s:export_configuration IMAGE=<image_ref>" if image.blank?

    K8sConfigurationExporter.export!(image)
  end
end
