# frozen_string_literal: true

module PermissionsExtends
  extend ActiveSupport::Concern

  included do
    def creation_enabled?
      return false unless Decidim::Initiatives.creation_enabled
      return true if no_authorizations_available?
      return true if no_create_permission_on_initiative_type?

      user_can_create? && authorized_to_create?
    end

    def can_vote?
      return false unless initiative.votes_enabled?
      return false unless initiative.organization&.id == user.organization&.id
      return false unless initiative.votes.where(author: user).empty?

      authorized_to_vote?
    end

    private

    def no_create_permission_on_initiative_type?
      return true if initiative_type.nil?
      return true if initiative_type.permissions.nil?
      return true if initiative_type.permissions.keys.empty?

      initiative_type.permissions.keys.exclude?("create")
    end

    def no_authorizations_available?
      organization = user&.organization
      organization&.available_authorizations&.empty?
    end

    def user_can_create?
      return true if Decidim::Initiatives.do_not_require_authorization
      return true if Decidim::Initiatives::UserAuthorizations.for(user).any?

      false
    end

    def authorized_to_create?
      return true if initiative_type.nil?
      return true if initiative_type.permissions.nil?

      result = authorized?(:create, permissions_holder: initiative_type)
      result != false
    end

    def authorized_to_vote?
      return true if initiative&.type.nil?
      return true if initiative.type.permissions.nil?
      return true unless initiative.type.permissions.keys.include?("vote")
      return true if Decidim::Initiatives.do_not_require_authorization

      result = authorized?(:vote, resource: initiative, permissions_holder: initiative.type)
      result == true
    end
  end
end

Decidim::Initiatives::Permissions.class_eval do
  include(PermissionsExtends)
end
