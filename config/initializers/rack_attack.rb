# frozen_string_literal: true

require "decidim_app/rack_attack"
require "decidim_app/rack_attack/throttling"
require "decidim_app/rack_attack/fail2ban"

# Enabled by default in production
# Can be deactivated with 'ENABLE_RACK_ATTACK=0'
# frozen_string_literal: true

require "decidim_app/rack_attack"
require "decidim_app/rack_attack/throttling"
require "decidim_app/rack_attack/fail2ban"

DecidimApp::RackAttack.deactivate_decidim_throttling!

# Enabled by default in production
# Can be deactivated with 'ENABLE_RACK_ATTACK=0'
if DecidimApp::RackAttack.rack_enabled?
  DecidimApp::RackAttack.enable_rack_attack!
  DecidimApp::RackAttack.apply_configuration
else
  DecidimApp::RackAttack.disable_rack_attack!
end

DecidimApp::RackAttack.info!