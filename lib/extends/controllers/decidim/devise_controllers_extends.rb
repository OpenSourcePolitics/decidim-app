# frozen_string_literal: true

module DeviseControllersExtends
  # Skip authorization handler by default
  def skip_first_login_authorization?
    ActiveRecord::Type::Boolean.new.cast(ENV.fetch("SKIP_FIRST_LOGIN_AUTHORIZATION", "false"))
  end
end

Decidim::DeviseControllers.module_eval do
  prepend(DeviseControllersExtends)
end
