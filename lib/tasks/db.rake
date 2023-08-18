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
  end
end
