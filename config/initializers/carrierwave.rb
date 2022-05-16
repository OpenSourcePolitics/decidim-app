# frozen_string_literal: true

# Default CarrierWave setup.
if Rails.env.production?
  CarrierWave.configure do |config|
    if Rails.application.secrets.dig(:scaleway, :id).blank?
      config.permissions = 0o666
      config.directory_permissions = 0o777
      config.storage = :file
      config.enable_processing = !Rails.env.test?
    else
      config.fog_provider = "fog/aws"
      config.fog_credentials = {
        provider: "AWS",
        aws_access_key_id: Rails.application.secrets.dig(:scaleway, :id),
        aws_secret_access_key: Rails.application.secrets.dig(:scaleway, :token),
        aws_signature_version: 4,
        region: "fr-par",
        host: "s3.fr-par.scw.cloud",
        endpoint: "https://s3.fr-par.scw.cloud",
        enable_signature_v4_streaming: false
      }
      config.storage = :fog
      # config.fog_use_ssl_for_aws = false
      # config.enable_processing = false
      # config.fog_public = false # optional, defaults to true
      config.fog_directory = Rails.application.secrets.dig(:scaleway, :bucket_name)
      config.fog_attributes = {
        "Cache-Control" => "max-age=#{365.days.to_i}",
        "X-Content-Type-Options" => "nosniff"
      }
    end
    # This needs to be set for correct attachment file URLs in emails
    # DON'T FORGET to ALSO set this in `config/application.rb`
    config.asset_host = "https://#{Rails.application.secrets[:asset_host]}/" if Rails.application.secrets[:asset_host].present?
  end
end
