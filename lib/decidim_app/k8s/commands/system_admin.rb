# frozen_string_literal: true

require "decidim_app/k8s/command"

module DecidimApp
  module K8s
    module Commands
      class SystemAdmin < DecidimApp::K8s::Command
        register_topic :system_admin

        def initialize(configuration)
          @configuration = configuration
        end

        def call
          install_or_update

          broadcast_status(system_admin)
        end

        def install_or_update
          if system_admin.update(@configuration)
            register_status(:updated, :ok)
          else
            register_status(:updated, :invalid, system_admin.tap(&:valid?).errors.messages)
          end
        end

        def system_admin
          @system_admin ||= Decidim::System::Admin.find_or_initialize_by(email: @configuration[:email])
        end
      end
    end
  end
end
