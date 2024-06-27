# frozen_string_literal: true

require "active_support/concern"
module InitiativeFormExtends
  extend ActiveSupport::Concern

  included do
    def scoped_type_id
      return unless type

      type.scopes.find_by(decidim_scopes_id: decidim_scope_id)&.id
    end

    private

    def type
      @type ||= type_id ? Decidim::InitiativesType.find(type_id) : context.initiative&.type
    end
  end
end

Decidim::Initiatives::Admin::InitiativeForm.include(InitiativeFormExtends)
