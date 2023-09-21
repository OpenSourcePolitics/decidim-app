# frozen_string_literal: true

require "decidim_app/decidim_initiatives"

# Required to define the Decidim::Initiatives configurations
DecidimApp::DecidimInitiatives.apply_configuration if DecidimApp::DecidimInitiatives.decidim_initiatives_enabled?
