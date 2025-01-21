# frozen_string_literal: true

# Default CarrierWave setup.
if Rails.env.production?
  CarrierWave.configure do |config|
    if Rails.application.secrets.dig(:storage, :s3, :access_key_id).blank?
      config.permissions = 0o666
      config.directory_permissions = 0o777
      config.storage = :file
      config.enable_processing = !Rails.env.test?
    else
      config.fog_provider = "fog/aws"
      config.fog_credentials = {
        provider: "AWS",
        aws_access_key_id: Rails.application.secrets.dig(:storage, :s3, :access_key_id),
        aws_secret_access_key: Rails.application.secrets.dig(:storage, :s3, :secret_access_key),
        aws_signature_version: 4,
        region: "fr-par",
        host: Rails.application.secrets.dig(:storage, :s3, :endpoint),
        endpoint: Rails.application.secrets.dig(:storage, :s3, :bucket) == "mybucket" ? "http://#{Rails.application.secrets.dig(:storage, :s3, :endpoint)}" : "https://#{Rails.application.secrets.dig(:storage, :s3, :endpoint)}",
        enable_signature_v4_streaming: false
      }
      config.storage = :fog
      config.fog_directory = Rails.application.secrets.dig(:storage, :s3, :bucket)
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
