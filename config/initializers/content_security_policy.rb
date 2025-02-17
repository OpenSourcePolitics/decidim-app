# frozen_string_literal: true

# For tuning the Content Security Policy, check the Decidim documentation site
# https://docs.decidim.org/develop/en/customize/content_security_policy

CSP = {
  "default-src" => %w(decidim.storage.opensourcepolitics.eu templates.opensourcepolitics.net),
  "img-src" => %w(decidim.storage.opensourcepolitics.eu),
  "media-src" => %w(decidim.storage.opensourcepolitics.eu www.youtube.com),
  "script-src" => %w(decidim.storage.opensourcepolitics.eu templates.opensourcepolitics.net tarteaucitron.io unpkg.com),
  "style-src" => %w(decidim.storage.opensourcepolitics.eu templates.opensourcepolitics.net),
  "font-src" => %w(decidim.storage.opensourcepolitics.eu),
  "connect-src" => %w(decidim.storage.opensourcepolitics.eu),
  "frame-src" => %w(decidim.storage.opensourcepolitics.eu)
}.freeze

if Rails.application.secrets.dig(:storage, :minio, :endpoint).presence == "http://minio:9000"
  CSP["default-src"] << Rails.application.secrets.dig(:storage, :minio, :endpoint)
  CSP["img-src"] << Rails.application.secrets.dig(:storage, :minio, :endpoint)
  CSP["media-src"] << Rails.application.secrets.dig(:storage, :minio, :endpoint)
  CSP["script-src"] << Rails.application.secrets.dig(:storage, :minio, :endpoint)
  CSP["style-src"] << Rails.application.secrets.dig(:storage, :minio, :endpoint)
  CSP["connect-src"] << Rails.application.secrets.dig(:storage, :minio, :endpoint)
  CSP["frame-src"] << Rails.application.secrets.dig(:storage, :minio, :endpoint)
end

Decidim.configure do |config|
  config.content_security_policies_extra = CSP
end
