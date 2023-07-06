# frozen_string_literal: true

require "decidim/admin_creator"
require "decidim/system_admin_creator"
require "k8s/configuration_exporter"

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

  desc "Create admin user with decidim_app:create_admin name='John Doe' nickname='johndoe' email='john@example.org', password='decidim123456' organization_id='1'"
  task create_admin: :environment do
    Decidim::AdminCreator.create!(ENV) ? puts("Admin created successfully") : puts("Admin creation failed")
  end

  desc "Create system user with decidim_app:create_system_admin email='john@example.org', password='decidim123456'"
  task create_system_admin: :environment do
    Decidim::SystemAdminCreator.create!(ENV) ? puts("System admin created successfully") : puts("System admin creation failed")
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
      K8s::ConfigurationExporter.dump_db
    end

    desc "usage: bundle exec rails k8s:export_configuration IMAGE=<docker_image_ref>"
    task export_configuration: :environment do
      image = ENV["IMAGE"]
      raise "You must specify a docker image, usage: bundle exec rails k8s:export_configuration IMAGE=<image_ref>" if image.blank?

      K8s::ConfigurationExporter.export!(image)
    end
  end
end
