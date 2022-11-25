# frozen_string_literal: true

module SessionControllerExtends
  extend ActiveSupport::Concern

  included do
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

    # Skip authorization handler by default
    def skip_fist_login_authorization?
      ActiveRecord::Type::Boolean.new.cast(ENV.fetch("SKIP_FIRST_LOGIN_AUTHORIZATION", "false"))
    end
  end
end

Decidim::Devise::SessionsController.class_eval do
  include(SessionControllerExtends)
end
