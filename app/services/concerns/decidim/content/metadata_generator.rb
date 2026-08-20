# frozen_string_literal: true

module Decidim
  module Content
    module MetadataGenerator
      extend ActiveSupport::Concern
      included do
        include LabelsGenerator
        include WarningsGenerator
        include StatsGenerator

        def metadata_for(instance)
          {
            labels: labels_for(instance),
            warnings: warnings_for(instance),
            stats: stats_for(instance)
          }
        end
      end
    end
  end
end
