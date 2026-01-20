# frozen_string_literal: true

# For tuning the Content Security Policy, check the Decidim documentation site
# https://docs.decidim.org/develop/en/customize/content_security_policy

content_security_policies = {
  "default-src" => %w(decidim.storage.opensourcepolitics.eu templates.opensourcepolitics.net),
  "img-src" => %w(decidim.storage.opensourcepolitics.eu https://*.tile.openstreetmap.org),
  "media-src" => %w(decidim.storage.opensourcepolitics.eu www.youtube.com),
  "script-src" => %w(decidim.storage.opensourcepolitics.eu templates.opensourcepolitics.net tarteaucitron.io unpkg.com blob:),
  "style-src" => %w(decidim.storage.opensourcepolitics.eu templates.opensourcepolitics.net),
  "font-src" => %w(decidim.storage.opensourcepolitics.eu),
  "connect-src" => %w(decidim.storage.opensourcepolitics.eu https://cdn.jsdelivr.net),
  "frame-src" => %w(decidim.storage.opensourcepolitics.eu)
}

minio_endpoint = ENV.fetch("AWS_ENDPOINT", "https://#{ENV.fetch("OBJECTSTORE_S3_HOST", nil)}")
if minio_endpoint.presence == "http://minio:9000"
  content_security_policies["default-src"] << minio_endpoint
  content_security_policies["img-src"] << minio_endpoint
  content_security_policies["media-src"] << minio_endpoint
  content_security_policies["script-src"] << minio_endpoint
  content_security_policies["style-src"] << minio_endpoint
  content_security_policies["connect-src"] << minio_endpoint
  content_security_policies["frame-src"] << minio_endpoint
end

Decidim.configure do |config|
  config.content_security_policies_extra = content_security_policies
end
