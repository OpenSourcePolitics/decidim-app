# frozen_string_literal: true

# For tuning the Content Security Policy, check the Decidim documentation site
# https://docs.decidim.org/develop/en/customize/content_security_policy

CSPS = %w(minio:*
          localhost:*
          fonts.gstatic.com
          fonts.googleapis.com
          decidim.storage.opensourcepolitics.eu
          club.decidim.opensourcepolitics.eu
          templates.opensourcepolitics.net
          unpkg.com
          www.youtube.com
          ).freeze
# tarteaucitron.io

# rubocop:disable Layout/LineLength
Decidim.configure do |config|
  config.content_security_policies_extra = {
    "default-src" => CSPS + %w(http://minio:*),
    "script-src" => CSPS + %w(http://minio:*),
    "style-src" => CSPS + %w(http://minio:*),
    "img-src" => CSPS + %w(http://minio:*),
    "font-src" => CSPS + %w(http://minio:*),
    "connect-src" => CSPS + %w(http://minio:*),
    "frame-src" => CSPS + %w(http://minio:*),
    "media-src" => CSPS + %w(http://minio:)
  }
end
# rubocop:enable Layout/LineLength
