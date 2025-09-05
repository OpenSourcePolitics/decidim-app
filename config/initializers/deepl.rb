# frozen_string_literal: true

# Configuration du client DeepL (gem deepl-rb)
DeepL.configure do |config|
  config.auth_key = Rails.application.secrets.translator[:api_key]
  config.host     = Rails.application.secrets.translator[:host]
end
