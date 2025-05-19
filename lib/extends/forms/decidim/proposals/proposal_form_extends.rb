# frozen_string_literal: true

require "active_support/concern"

module ProposalFormExtends
  extend ActiveSupport::Concern

  included do
    attribute :require_category, :boolean, default: Decidim::Proposals.config.require_category
    attribute :require_scope, :boolean, default: Decidim::Proposals.config.require_scope

    validates :category_id, presence: true, if: ->(form) { form.require_category? }
    validates :scope_id, presence: true, if: ->(form) { form.require_scope? }
    validate :check_category, if: ->(form) { form.require_category? }
    validate :check_scope, if: ->(form) { form.require_scope? }
    validate :validate_scope_belongs_to_component

    def categories_enabled?
      categories&.any?
    end

    def scopes_enabled?
      current_component.scopes_enabled? && current_component.has_subscopes?
    end

    def require_category?
      current_component.settings.require_category && categories_enabled?
    end

    def require_scope?
      current_component.settings.require_scope && scopes_enabled?
    end

    private

    def check_category
      errors.add(:category, :blank) if (category_id.blank? || category.blank?) && require_category?
    end

    def check_scope
      errors.add(:scope, :blank) if (scope_id.blank? || scope.blank?) && require_scope?
    end

    def validate_scope_belongs_to_component
      return if scope_id.blank? || scope.blank? || current_component.scope.blank?

      unless scope.ancestor_of?(current_component.scope) ||
        current_component.scope.descendants.include?(scope) ||
        scope == current_component.scope
        errors.add(:scope_id, :invalid_scope)
      end
    end
  end
end

Decidim::Proposals::ProposalForm.include(ProposalFormExtends)
