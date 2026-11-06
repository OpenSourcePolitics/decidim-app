# frozen_string_literal: true

module DecidimApp
  # Adds a long-lived Cache-Control header to the fingerprinted Shakapacker
  # packs served from public/decidim-packs when Rails serves static files
  # itself (RAILS_SERVE_STATIC_FILES). Other public files (robots.txt,
  # apple-touch-icon.png, 422.html...) and the packs manifest keep the default
  # behaviour, so they are never cached as immutable.
  class StaticCacheControl
    CACHE_CONTROL = "public, max-age=31536000, immutable"
    PREFIXES = %w(/decidim-packs/).freeze
    CACHEABLE_STATUSES = [200, 304].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers["Cache-Control"] = CACHE_CONTROL if cacheable?(env["PATH_INFO"].to_s, status)
      [status, headers, body]
    end

    private

    def cacheable?(path, status)
      CACHEABLE_STATUSES.include?(status.to_i) &&
        PREFIXES.any? { |prefix| path.start_with?(prefix) } &&
        !File.basename(path).start_with?("manifest")
    end
  end
end
