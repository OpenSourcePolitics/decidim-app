# frozen_string_literal: true

module Decidim
  class SurveysService < DatabaseService
    def orphans
      Decidim::Surveys::Survey
        .where.not(decidim_component_id: [Decidim::Component.ids])
        .pluck(:id, :decidim_component_id).each do |s|
        @logger.info s.inspect if @verbose
      end
    end

    def clear
      @logger.info "Removing orphans rows in database for Decidim::SurveysService ..." if @verbose

      removed = Decidim::Surveys::Survey
                .where.not(decidim_component_id: [Decidim::Component.ids])
                .destroy_all

      @logger.info({ "Decidim::Surveys::Survey" => removed.size }) if @verbose
    end
  end
end
