# frozen_string_literal: true

require "active_support/concern"
module AuthorizationExtends
  extend ActiveSupport::Concern

  included do
    after_commit :export_to_user_extended_data, if: proc { |authorization|
      ENV["AUTO_EXPORT_AUTHORIZATIONS_DATA_TO_USER_DATA_ENABLED_FOR"].to_s.split(",").include?(authorization.name)
    }

    def export_to_user_extended_data
      Decidim::AuthorizationDataToUserDataService.run(name: name, user: user)
    end
  end
end

Decidim::Authorization.include(AuthorizationExtends)
