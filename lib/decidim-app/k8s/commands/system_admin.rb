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
          system_admin = Decidim::System::Admin.find_or_initialize_by(email: @configuration[:email])

          if system_admin.update(@configuration)
            K8s::Manager.logger.info("System admin user #{system_admin.email} updated")
          else
            K8s::Manager.logger.info("System admin user #{system_admin.email} could not be updated")
            system_admin.tap(&:valid?).errors.messages.each do |error|
              K8s::Manager.logger.info(error)
            end
          end

          system_admin.reload
        end
      end
    end
  end
end
