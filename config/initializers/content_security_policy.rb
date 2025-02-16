# frozen_string_literal: true

# For tuning the Content Security Policy, check the Decidim documentation site
# https://docs.decidim.org/develop/en/customize/content_security_policy

provider = Rails.application.secrets.dig(:storage, :provider) || ""

s3_endpoint = Rails.application.secrets.dig(:storage, provider&.to_sym, :endpoint) if provider.present?
S3_ENDPOINT = if s3_endpoint&.start_with?("https://")
                s3_endpoint.split("https://").last
              else
                s3_endpoint || ""
              end

Decidim.configure do |config|
  config.content_security_policies_extra = {
    "default-src" => S3_ENDPOINT + %w(templates.opensourcepolitics.net),
    "img-src" => S3_ENDPOINT,
    "media-src" => S3_ENDPOINT + %w(www.youtube.com),
    "script-src" => S3_ENDPOINT + %w(templates.opensourcepolitics.net tarteaucitron.io unpkg.com),
    "style-src" => S3_ENDPOINT + %w(templates.opensourcepolitics.net),
    "font-src" => S3_ENDPOINT,
    "connect-src" => S3_ENDPOINT,
    "frame-src" => S3_ENDPOINT
  }
end
