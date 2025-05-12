# frozen_string_literal: true

require "active_support/concern"

module ProposalFormExtends
  extend ActiveSupport::Concern

  included do
    attribute :require_category, :boolean, default: Decidim::Proposals.config.require_category
    attribute :require_scope, :boolean, default: Decidim::Proposals.config.require_scope

    validate :validate_category
    validate :validate_scope
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

    def validate_category
      if require_category? && category_id.blank?
        errors.add(:category, :blank)
      elsif category_id.present? && category.blank?
        errors.add(:category_id, :invalid)
      end
    end

    def validate_scope
      if require_scope? && scope_id.blank?
        errors.add(:scope, :blank)
      elsif scope_id.present? && scope.blank?
        errors.add(:scope_id, :invalid)
      end
    end

    def validate_scope_belongs_to_component
      return if scope_id.blank? || scope.blank? || current_component.scope.blank?

      unless scope.ancestor_of?(current_component.scope) ||
             scope.descendants.include?(current_component.scope) ||
             scope == current_component.scope
        errors.add(:scope_id, :invalid_scope)
      end
    end
  end
end

Decidim::Proposals::ProposalForm.include(ProposalFormExtends)
