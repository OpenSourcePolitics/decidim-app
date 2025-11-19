# frozen_string_literal: true

module PermissionsExtends
  extend ActiveSupport::Concern

  included do
    def creation_enabled?
      return false unless Decidim::Initiatives.creation_enabled
      return true if no_authorizations_available?

      user_can_create? && authorized?(:create, permissions_holder: initiative_type)
    end

    private

    def no_authorizations_available?
      user&.organization&.available_authorizations&.empty?
    end

    def user_can_create?
      Decidim::Initiatives.do_not_require_authorization ||
        Decidim::Initiatives::UserAuthorizations.for(user).any? ||
        Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?
    end
  end
end

Decidim::Initiatives::Permissions.class_eval do
  include(PermissionsExtends)
end
