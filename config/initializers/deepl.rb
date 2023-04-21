# frozen_string_literal: true

# DeepL Translation service configuration
DeepL.configure do |config|
  config.auth_key = Rails.application.secrets.translator[:api_key]
  config.host = Rails.application.secrets.translator[:host]
end
