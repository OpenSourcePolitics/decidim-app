# frozen_string_literal: true

Decidim::Gallery.configure do |config|
  config.enable_animation = Rails.application.secrets.dig(:modules, :gallery, :enable_animation)
end
