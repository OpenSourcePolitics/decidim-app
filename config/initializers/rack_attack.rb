# frozen_string_literal: true

require "decidim_app/rack_attack"
require "decidim_app/rack_attack/throttling"
require "decidim_app/rack_attack/fail2ban"

# Enabled by default in production
# Can be deactivated with 'ENABLE_RACK_ATTACK=0'
DecidimApp::RackAttack.apply_configuration if DecidimApp::RackAttack.rack_enabled?
