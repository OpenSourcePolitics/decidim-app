# frozen_string_literal: true

require "active_support/concern"

module OmniauthRegistrationFormExtends
  extend ActiveSupport::Concern

  included do
    def normalized_nickname
      source = Decidim::Env.new("OMNIAUTH_IGNORE_NICKNAME", false).to_boolean_string == "true" ? name : (nickname || name)
      Decidim::UserBaseEntity.nicknamize(source, organization: current_organization)
    end
  end
end

Decidim::OmniauthRegistrationForm.include(OmniauthRegistrationFormExtends)
