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
      Rake::Task["migrate:db:force"].invoke
      Rake::Task["decidim:upgrade:migrate_wysiwyg_content"].invoke
      Rake::Task["decidim:upgrade:moderation:fix_blocked_user_panel"].invoke
      Rake::Task["decidim:upgrade:fix_duplicate_endorsements"].invoke
      Rake::Task["decidim:upgrade:fix_short_urls"].invoke
      Rake::Task["decidim:upgrade:clean:searchable_resources"].invoke
      Rake::Task["decidim:upgrade:clean:notifications"].invoke
      Rake::Task["decidim:upgrade:clean:follows"].invoke
      Rake::Task["decidim:upgrade:clean:action_logs"].invoke
      Rails.logger.warn "(decidim_app:k8s:upgrade)> Successfully upgraded!"
    rescue StandardError => e
      Rails.logger.error "(decidim_app:k8s:upgrade)> An error occured : #{e.message}"
    end
  end
end
