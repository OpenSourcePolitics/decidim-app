# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Admin
    module ScopesControllerExtends
      extend ActiveSupport::Concern
      included do
        def index
          enforce_permission_to :read, :scope
          @scopes = children_scopes.sort_by(&:weight)
        end

        def update
          enforce_permission_to :update, :scope, scope: scope
          @form = form(ScopeForm).from_params(params)

          return update_scopes if params[:id] == "refresh_scopes"

          UpdateScope.call(scope, @form) do
            on(:ok) do
              flash[:notice] = I18n.t("scopes.update.success", scope: "decidim.admin")
              redirect_to current_scopes_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("scopes.update.error", scope: "decidim.admin")
              render :edit
            end
          end
        end

        private

        def update_scopes
          ::Admin::ReorderScopes.call(current_organization, :scopes, params[:manifests]) do
            on(:ok) do
              flash[:notice] = I18n.t("scopes.update.success", scope: "decidim.admin")
            end
          end
        end
      end
    end
  end
end

Decidim::Admin::ScopesController.include(Decidim::Admin::ScopesControllerExtends)
