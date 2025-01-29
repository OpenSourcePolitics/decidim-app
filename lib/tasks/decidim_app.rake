# frozen_string_literal: true

namespace :decidim_app do
  namespace :k8s do
    # This task is used to upgrade your decidim-app to the latest version
    # Meant to be used in a CI/CD pipeline or a k8s job/operator
    # You can add your own customizations here
    desc "Upgrade a decidim-app"
    task upgrade: :environment do
      Rails.logger.warn "(decidim_app:k8s:upgrade)> Starting upgrade..."
      Rake::Task["db:migrate"].invoke
      Rails.logger.warn "(decidim_app:k8s:upgrade)> Successfully upgraded!"
    rescue StandardError => e
      Rails.logger.failure "(decidim_app:k8s:upgrade)> An error occured : #{e.message}"
      # Rake::Task["db:migrate"].invoke
    end
  end
end