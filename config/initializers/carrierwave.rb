# frozen_string_literal: true

# Default CarrierWave setup.
#
CarrierWave.configure do |config|
  config.permissions = 0o666
  config.directory_permissions = 0o777
  config.storage = :file
  config.enable_processing = !Rails.env.test?
  # This needs to be set for correct attachment file URLs in emails
  # DON'T FORGET to ALSO set this in `config/application.rb`
  # config.asset_host = "https://your.server.url"
end

# Setup CarrierWave to use Amazon S3. Add `gem "fog-aws" to your Gemfile.
if ENV["HEROKU_APP_NAME"].present? && Rails.env.production?
  require "carrierwave/storage/fog"

  CarrierWave.configure do |config|
    config.storage = :fog
    config.fog_provider = "fog/aws" # required
    config.fog_credentials = {
      provider: "AWS", # required
      aws_access_key_id: Rails.application.secrets.aws_access_key_id, # required
      aws_secret_access_key: Rails.application.secrets.aws_secret_access_key, # required
      region: "eu-central-1", # optional, defaults to 'us-east-1'
      host: "s3.eu-central-1.amazonaws.com" # optional, defaults to nil
    }
    config.fog_directory = "decidim-heroku" # required
    config.fog_public = true # optional, defaults to true
    config.fog_attributes = { "Cache-Control" => "max-age=#{365.days.to_i}" } # optional, defaults to {}
    config.storage = :fog
  end
end
