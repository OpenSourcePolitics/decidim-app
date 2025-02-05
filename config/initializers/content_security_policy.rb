# frozen_string_literal: true

# For tuning the Content Security Policy, check the Decidim documentation site
# https://docs.decidim.org/develop/en/customize/content_security_policy

# rubocop:disable Layout/LineLength
Decidim.configure do |config|
  config.content_security_policies_extra = {
    "default-src" => "localhost:* fonts.gstatic.com decidim.storage.opensourcepolitics.eu club.decidim.opensourcepolitics.eu:* templates.opensourcepolitics.net unpkg.com fonts.googleapis.com tarteaucitron.io",
    "script-src" => "localhost:* fonts.gstatic.com decidim.storage.opensourcepolitics.eu club.decidim.opensourcepolitics.eu:* templates.opensourcepolitics.net unpkg.com fonts.googleapis.com tarteaucitron.io",
    "style-src" => "localhost:* fonts.gstatic.com decidim.storage.opensourcepolitics.eu club.decidim.opensourcepolitics.eu:* templates.opensourcepolitics.net unpkg.com fonts.googleapis.com tarteaucitron.io",
    "img-src" => "localhost:* fonts.gstatic.com decidim.storage.opensourcepolitics.eu club.decidim.opensourcepolitics.eu:* templates.opensourcepolitics.net unpkg.com fonts.googleapis.com tarteaucitron.io",
    "font-src" => "localhost:* fonts.gstatic.com decidim.storage.opensourcepolitics.eu club.decidim.opensourcepolitics.eu:* templates.opensourcepolitics.net unpkg.com fonts.googleapis.com tarteaucitron.io",
    "connect-src" => "localhost:* fonts.gstatic.com decidim.storage.opensourcepolitics.eu club.decidim.opensourcepolitics.eu:* templates.opensourcepolitics.net unpkg.com fonts.googleapis.com tarteaucitron.io",
    "frame-src" => "localhost:* www.youtube.com fonts.gstatic.com decidim.storage.opensourcepolitics.eu club.decidim.opensourcepolitics.eu:* templates.opensourcepolitics.net unpkg.com fonts.googleapis.com tarteaucitron.io",
    "media-src" => "localhost:* fonts.gstatic.com decidim.storage.opensourcepolitics.eu club.decidim.opensourcepolitics.eu:* templates.opensourcepolitics.net unpkg.com fonts.googleapis.com tarteaucitron.io"
  }
end
# rubocop:enable Layout/LineLength
