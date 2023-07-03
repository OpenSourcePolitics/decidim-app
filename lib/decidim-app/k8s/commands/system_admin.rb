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
          Decidim::System::Admin.find_or_initialize_by(email: @configuration["email"])
                                .tap { |system_admin| system_admin.update!(@configuration) }
        end
      end
    end
  end
end
