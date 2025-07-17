# frozen_string_literal: true

require "active_support/concern"

module OmniauthRegistrationFormExtends
  extend ActiveSupport::Concern

  included do
    def normalized_nickname
      source = Rails.application.secrets.dig(:decidim, :omniauth, :ignore_nickname) ? name : (nickname || name)
      Decidim::UserBaseEntity.nicknamize(source, organization: current_organization)
    end
  end
end

Decidim::OmniauthRegistrationForm.include(OmniauthRegistrationFormExtends)
