# frozen_string_literal: true

require "active_support/concern"

module AccountFormExtends
  extend ActiveSupport::Concern

  included do
    attribute :omniauth_provider

    def sign_in_with_omniauth?
      providers = context.current_organization.enabled_omniauth_providers&.keys&.map(&:to_s)
      providers.any? && providers.include?(omniauth_provider)
    end

    def validate_old_password
      user = context.current_user

      return true if password.blank? && sign_in_with_omniauth?

      if user.email != email || password.present?
        return true if user.valid_password?(old_password)

        errors.add :old_password, :invalid
        false
      end
    end
  end
end

Decidim::AccountForm.include(AccountFormExtends)
