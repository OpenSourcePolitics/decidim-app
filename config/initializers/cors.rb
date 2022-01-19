Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    resource '/decidim-packs/*',
             headers: :any,
             methods: [:get, :head]
  end
end