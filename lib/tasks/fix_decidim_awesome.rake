# frozen_string_literal: true

# Fix for decidim_awesome missing migrations task in 0.31
namespace :decidim_decidim_awesome do
  namespace :install do
    desc "Copy migrations from decidim_decidim_awesome to application"
    task :migrations do
      # Get the decidim_awesome engine
      Decidim::DecidimAwesome::Engine

      # Copy migrations from the engine
      if Rake::Task.task_defined?("railties:install:migrations")
        ENV["FROM"] = "decidim_decidim_awesome"
        Rake::Task["railties:install:migrations"].invoke
      end
    end
  end
end
