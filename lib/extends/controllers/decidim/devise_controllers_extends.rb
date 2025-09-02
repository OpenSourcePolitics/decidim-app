# frozen_string_literal: true

module DeviseControllersExtends
  extend ActiveSupport::Concern

  included do
    # Skip authorization handler by default
    def skip_first_login_authorization?
      Rails.application.secrets.dig(:decidim, :skip_first_login_authorization)
    end
  end
end

Decidim::DeviseControllers.class_eval do
  include(DeviseControllersExtends)
end
