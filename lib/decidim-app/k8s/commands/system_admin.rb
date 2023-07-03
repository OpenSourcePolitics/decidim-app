# frozen_string_literal: true

require "decidim-app/k8s/manager"

module DecidimApp
  module K8s
    module Commands
      class SystemAdmin
        def self.run(configuration)
          new(configuration).run
        end

        def initialize(configuration)
          @configuration = configuration
        end

        def run

        end
      end
    end
  end
end
