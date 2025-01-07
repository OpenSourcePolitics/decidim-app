# frozen_string_literal: true

namespace :decidim do
  namespace :db do
    namespace :notification do
      desc "List notifications related to orphans data"
      task orphans: :environment do
        Decidim::NotificationService.new(verbose: true).orphans
      end

      desc "Delete notifications related to orphans data"
      task clean: :environment do
        Decidim::NotificationService.new(verbose: true).clear
      end
    end

    namespace :admin_log do
      desc "List admin log related to orphans data"
      task orphans: :environment do
        Decidim::ActionLogService.new(verbose: true).orphans
      end

      desc "Delete admin log related to orphans data"
      task clean: :environment do
        Decidim::ActionLogService.new(verbose: true).clear
      end
    end

    namespace :surveys do
      desc "List surveys related to deleted component"
      task orphans: :environment do
        Decidim::SurveysService.new(verbose: true).orphans
      end

      desc "Delete surveys related to deleted component"
      task clean: :environment do
        Decidim::SurveysService.new(verbose: true).clear
      end
    end

    namespace :versions do
      desc "Clean versions"
      task clean: :environment do
        puts "(decidim:db:versions:clean) #{Time.current.strftime("%d-%m-%Y %H:%M:%S")}> Executing PapertrailVersionsJob..."
        retention = Rails.application.secrets.dig(:decidim, :database, :versions, :clean, :retention)
        retention = retention.months.ago
        puts "(decidim:db:versions:clean) #{Time.current.strftime("%d-%m-%Y %H:%M:%S")}> Clean versions created before #{retention.strftime("%d-%m-%Y %H:%M:%S")}..."
        Decidim::PapertrailVersionsJob.perform_later(retention)
        puts "(decidim:db:versions:clean) #{Time.current.strftime("%d-%m-%Y %H:%M:%S")}> Job delayed to Sidekiq."
      end
    end

    namespace :restore do
      desc "Clear database dump to work with localhost"
      task local: :environment do
        puts "(decidim:db:restore:local) #{Time.current.strftime("%d-%m-%Y %H:%M:%S")}> Modifying Organization settings..."
        organization = Decidim::Organization.first
        organization.host = "localhost"
        organization.smtp_settings = {}
        organization.omniauth_settings = {}
        organization.save(validate: false)

        puts "(decidim:db:restore:local) #{Time.current.strftime("%d-%m-%Y %H:%M:%S")}> Changes done..."
      end
    end
  end
end
