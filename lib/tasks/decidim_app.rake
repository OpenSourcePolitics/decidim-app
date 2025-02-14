# frozen_string_literal: true

namespace :decidim_app do
  namespace :db do
    desc "Disable production configuration for restored database"
    task restore_local: :environment do
      Rails.logger.warn "(decidim_app:db:restore_local)> Disabling production configuration..."
      raise ArgumentError, "Multiple organizations found, please specify ORGANIZATION_ID environment variable" if Decidim::Organization.count > 1 && ENV["ORGANIZATION_ID"].blank?

      organization_id = ENV.fetch("ORGANIZATION_ID", 1)
      organization = Decidim::Organization.find(organization_id)
      organization.host = "localhost"
      organization.smtp_settings = {}
      organization.omniauth_settings = {}
      if organization.save!
        Rails.logger.warn "(decidim_app:db:restore_local)> Successfully disabled production configuration"
      else
        Rails.logger.warn "(decidim_app:db:restore_local)> Failed to disable production configuration"
      end

      Rails.logger.warn "(decidim_app:db:restore_local)> Terminated"
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn "(decidim_app:db:restore_local)> An error occured : #{e.message}"
    end
  end

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
