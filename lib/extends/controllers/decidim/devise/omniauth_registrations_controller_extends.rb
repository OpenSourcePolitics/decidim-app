# frozen_string_literal: true

module OmniauthRegistrationsControllerExtends
  extend ActiveSupport::Concern

  included do
    def sign_in_and_redirect(resource_or_scope, *args)
      strategy = request.env["omniauth.strategy"]
      provider = strategy.name
      session["omniauth.provider"] = provider
      session["omniauth.#{provider}.logout_policy"] = strategy.options[:logout_policy] if strategy.options[:logout_policy].present?
      session["omniauth.#{provider}.logout_path"] = strategy.options[:logout_path] if strategy.options[:logout_path].present?
      super
    end

    def after_sign_in_path_for(user)
      if user.present? && user.blocked?
        check_user_block_status(user)
      elsif !skip_first_login_authorization? && (first_login_and_not_authorized?(user) && !user.admin? && !pending_redirect?(user))
        decidim_verifications.first_login_authorizations_path
      else
        super
      end
    end

    private

    def skip_first_login_authorization?
      ActiveRecord::Type::Boolean.new.cast(ENV.fetch("SKIP_FIRST_LOGIN_AUTHORIZATION", "false"))
    end
  end
end

Decidim::Devise::OmniauthRegistrationsController.class_eval do
  include(OmniauthRegistrationsControllerExtends)
end
