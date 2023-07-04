# frozen_string_literal: true

require "decidim_app/k8s/configuration_exporter"
require "decidim_app/k8s/organization_exporter"
require "decidim_app/k8s/manager"

namespace :decidim_app do
  desc "Setup Decidim-app"
  task setup: :environment do
    # :nocov:
    puts "Running bundler installation"
    system("bundle install")
    puts "Installing engine migrations..."
    system("bundle exec rake railties:install:migrations")
    puts "Checking for migrations to apply..."
    migrations = `bundle exec rake db:migrate:status | grep down`
    if migrations.present?
      puts "Missing migrations :
#{migrations}"
      puts "Applying missing migrations..."
      system("bundle exec rake db:migrate")
    else
      puts "All migrations are up"
    end

    puts "Setup successfully terminated"
    # :nocov:
  end

  namespace :k8s do
    # This task is used to upgrade your decidim-app to the latest version
    # Meant to be used in a CI/CD pipeline or a k8s job/operator
    # You can add your own customizations here
    desc "Upgrade decidim-app"
    task upgrade: :environment do
      puts "Running db:migrate"
      Rake::Task["db:migrate"].invoke
    end

    desc "usage: bundle exec rails k8s:dump_db"
    task dump_db: :environment do
      DecidimApp::K8s::ConfigurationExporter.dump_db
    end

    desc "usage: bundle exec rails k8s:export_configuration IMAGE=<docker_image_ref>"
    task export_configuration: :environment do
      image = ENV["IMAGE"]
      raise "You must specify a docker image, usage: bundle exec rails k8s:export_configuration IMAGE=<image_ref>" if image.blank?

      DecidimApp::K8s::ConfigurationExporter.export!(image)
    end

    desc "Create external install with path='path/to/external_install_configuration.yml'"
    task external_install: :environment do
      DecidimApp::K8s::Manager.run(ENV["path"])
    end
  end
end
