# frozen_string_literal: true

namespace :decidim do
  Rails.logger = Logger.new(STDOUT)
  ActiveRecord::Base.logger = Logger.new(STDOUT)

  namespace :db do

    namespace :notification do
      desc "List notifications related to orphans data"
      task orphans: :environment do
        Decidim::Notification.distinct.pluck(:decidim_resource_type).each do |klass|
          puts klass
          model = klass.constantize
          puts Decidim::Notification
            .where(decidim_resource_type: klass)
            .where.not(decidim_resource_id: [model.ids])
            .pluck(:event_name, :decidim_resource_id, :extra).count
        end
        Rails.logger.close
      end

      desc "Delete notifications related to orphans data"
      task clean: :environment do
        Decidim::Notification.distinct.pluck(:decidim_resource_type).each do |klass|
          model = klass.constantize
          Decidim::Notification
            .where(decidim_resource_type: klass)
            .where.not(decidim_resource_id: [model.ids])
            .destroy_all
        end
      end
    end

    namespace :admin_log do
      desc "List admin log related to orphans data"
      task orphans: :environment do
        Decidim::ActionLog.distinct.pluck(:resource_type).each do |klass|
          puts klass
          model = klass.constantize
          puts Decidim::ActionLog
            .where(resource_type: klass)
            .where.not(resource_id: [model.ids])
            .pluck(:action, :resource_id, :extra).count
        end
        Rails.logger.close
      end

      desc "Delete admin log related to orphans data"
      task clean: :environment do
        Decidim::ActionLog.distinct.pluck(:resource_type).each do |klass|
          model = klass.constantize
          Decidim::ActionLog
            .where(resource_type: klass)
            .where.not(resource_id: [model.ids])
            .destroy_all
        end
      end
    end

    namespace :surveys do
      desc "List surveys related to deleted component"
      task orphans: :environment do
        Decidim::Surveys::Survey
          .where.not(decidim_component_id: [Decidim::Component.ids])
          .pluck(:id, :title, :decidim_component_id).each do |s|
            puts s.inspect
          end
        Rails.logger.close
      end

      desc "Delete surveys related to deleted component"
      task clean: :environment do
        Decidim::Surveys::Survey
          .where.not(decidim_component_id: [Decidim::Component.ids])
          .destroy_all

        Rails.logger.close
      end
    end

  end

end
