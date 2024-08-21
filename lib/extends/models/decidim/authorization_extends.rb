# frozen_string_literal: true

require "active_support/concern"
module AuthorizationExtends
  extend ActiveSupport::Concern

  included do
    after_commit :export_to_user_extended_data, if: proc { |authorization|
      Rails.application.secrets.dig(:decidim, :export_data_to_userdata_enabled_for).split(",").include?(authorization.name)
    }

    def export_to_user_extended_data
      Decidim::AuthorizationDataToUserDataService.run(name: name, user: user)
    end
  end
end

Decidim::Authorization.include(AuthorizationExtends)
