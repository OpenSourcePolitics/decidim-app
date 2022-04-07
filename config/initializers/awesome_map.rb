Rails.application.config.to_prepare do
  Decidim::Api::Schema.max_complexity = 5000
  Decidim::Api::Schema.max_depth = 50
end