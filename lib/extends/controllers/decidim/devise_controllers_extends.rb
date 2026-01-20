# frozen_string_literal: true

module DeviseControllersExtends
  extend ActiveSupport::Concern

  included do
    # Skip authorization handler by default
    def skip_first_login_authorization?
      Decidim::Env.new("SKIP_FIRST_LOGIN_AUTHORIZATION", false).to_boolean_string == "true"
    end
  end
end

Decidim::DeviseControllers.class_eval do
  include(DeviseControllersExtends)
end
