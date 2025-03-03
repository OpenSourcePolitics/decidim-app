# frozen_string_literal: true

module Admin
  class ReorderScopes < Decidim::Command
    def initialize(organization, scope, ids)
      @organization = organization
      @scope = scope
      @ids = ids
    end

    def call
      return broadcast(:invalid) if @ids.blank?

      reorder_scopes
      broadcast(:ok)
    end

    def collection
      @collection ||= Decidim::Scope.where(id: @ids, organization: @organization)
    end

    def reorder_scopes
      transaction do
        set_new_weights
      end
    end

    def set_new_weights
      @ids.each do |id|
        current_scope = collection.find { |block| block.id == id.to_i }
        next if current_scope.blank?

        current_scope.update!(weight: @ids.index(id) + 1)
      end
    end
  end
end
