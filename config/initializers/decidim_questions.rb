# frozen_string_literal: true

Decidim::QuestionCaptcha.configure do |config|
  config.api_endpoint = ENV["API_ENDPOINT"]
end
