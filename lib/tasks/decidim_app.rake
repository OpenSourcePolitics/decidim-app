# frozen_string_literal: true

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
    def env_organization_or_first(organization_id)
      Decidim::Organization.find(organization_id)
    rescue ActiveRecord::RecordNotFound
      Decidim::Organization.first
    end

    params = {
      organization: env_organization_or_first(ENV["organization_id"]),
      name: ENV["name"],
      nickname: ENV["nickname"],
      email: ENV["email"],
      password: ENV["password"]
    }

    missing = params.select { |_k, v| v.nil? }.keys

    raise "Missing parameters: #{missing.join(", ")}" unless missing.empty?

    Decidim::User.create!(organization: params[:organization],
                          name: params[:name],
                          nickname: params[:nickname],
                          email: params[:email],
                          password: params[:password],
                          password_confirmation: params[:password],
                          tos_agreement: "1",
                          admin: true)
  end

  desc "Create system user with decidim_app:create_system_admin email='john@example.org', password='decidim123456'"
  task create_system_admin: :environment do
    params = {
      email: ENV["email"],
      password: ENV["password"]
    }

    missing = params.select { |_k, v| v.nil? }.keys

    raise "Missing parameters: #{missing.join(", ")}" unless missing.empty?

    Decidim::System::Admin.create!(email: params[:email],
                                   password: params[:password],
                                   password_confirmation: params[:password])
  end
end
