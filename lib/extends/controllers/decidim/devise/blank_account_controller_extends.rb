# frozen_string_literal: true

module BlankAccountControllerExtends
  # Nothing to do here
  # Fix : decidim-admin-0.27.4/app/controllers/decidim/admin/application_controller.rb:6:in `<module:Admin>': uninitialized constant DecidimController (NameError)
end

Decidim::AccountController.class_eval do
  prepend(BlankAccountControllerExtends)
end
