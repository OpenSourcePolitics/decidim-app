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
      # TODO: Add tests
      task orphans: :environment do
        Rails.logger = Logger.new($stdout)
        # ActiveRecord::Base.logger = Logger.new($stdout)

        Decidim::Surveys::Survey
          .where.not(decidim_component_id: [Decidim::Component.ids])
          .pluck(:id, :title, :decidim_component_id).each do |s|
            puts s.inspect
          end
        Rails.logger.close
      end

      desc "Delete surveys related to deleted component"
      # TODO: Add tests
      task clean: :environment do
        Rails.logger = Logger.new($stdout)
        # ActiveRecord::Base.logger = Logger.new($stdout)

        Decidim::Surveys::Survey
          .where.not(decidim_component_id: [Decidim::Component.ids])
          .destroy_all

        Rails.logger.close
      end
    end
  end
end
