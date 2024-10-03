# frozen_string_literal: true

require "active_support/concern"

module NoAdminInitiativeFormExtends
  extend ActiveSupport::Concern

  included do
    validate :no_javascript_event_in_description

    private

    def no_javascript_event_in_description
      errors.add :description, :invalid if description =~ /on\w+=("|')/
    end
  end
end

Decidim::Initiatives::InitiativeForm.include(NoAdminInitiativeFormExtends)
