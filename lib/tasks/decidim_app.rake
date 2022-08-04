# frozen_string_literal: true

namespace :decidim_app do
  desc "Setup Decidim-app"
  task setup: :environment do
    puts "Running bundler installation"
    system("bundle install")
    puts "[Decidim Awesome] Installing migrations..."
    system("bundle exec rails decidim_decidim_awesome:install:migrations")
    puts "[Decidim Awesome] Installing webpacker..."
    system("bundle exec rails decidim_decidim_awesome:webpacker:install")
    puts "[Homepage Interactive map] Installing migrations..."
    system("bundle exec rake decidim_homepage_interactive_map:install:migrations")
    puts "[Term customizer] Installing migrations"
    system("bundle exec rails decidim_term_customizer:install:migrations")
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
  end
end
