# frozen_string_literal: true

require "active_support/concern"
module CreateOmniauthRegistrationExtends
  extend ActiveSupport::Concern

  included do
    def trigger_omniauth_registration
      # send welcome notification and email
      @user.after_confirmation
    end
  end
end

Decidim::CreateOmniauthRegistration.include(CreateOmniauthRegistrationExtends)
