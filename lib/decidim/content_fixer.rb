# frozen_string_literal: true

module Decidim
  class ContentFixer
    TAGS_TO_FIX = %w(a img).freeze

    def initialize(content, deprecated_endpoint, logger)
      @content = content
      @logger = logger
      @deprecated_endpoint = deprecated_endpoint
    end

    def self.repair(content, deprecated_endpoint, logger)
      new(content, deprecated_endpoint, logger).repair
    end

    def repair
      case @content
      when Hash
        @content.transform_values do |value|
          find_and_replace(value)
        end
      when String
        find_and_replace(@content)
      when Array
        @content.map do |value|
          find_and_replace(value)
        end
      else
        @logger.warn("Unsupported type #{@content.class}")

        nil
      end
    end

    def find_and_replace(content)
      wrapper = nokogiri_will_wrap_with_p?(content) ? "p" : "body"

      doc = Nokogiri::HTML(content)

      TAGS_TO_FIX.each do |tag|
        replace_urls(doc, tag)
      end

      doc.css(wrapper).inner_html
    end

    def blobs
      @blobs ||= ActiveStorage::Blob.pluck(:filename, :id)
    end

    def replace_urls(doc, tag)
      attribute = tag == "img" ? "src" : "href"

      doc.css(tag).each do |source|
        next unless source[attribute].include?(@deprecated_endpoint)

        new_source = new_source(source[attribute])

        next unless new_source

        @logger.info "Replacing #{source[attribute]} with #{new_source}"
        source[attribute] = new_source
      end
    end

    def new_source(source)
      uri = URI.parse(source)
      filename = if source.include?("response-content-disposition")
                   CGI.parse(uri.query)["response-content-disposition"].first.match(/filename=("?)(.+)\1/)[2]
                 else
                   uri.path.split("/").last
                 end
      _filename, id = blobs.select { |blob, _id| ActiveSupport::Inflector.transliterate(blob) == filename }.first

      find_service_url_for_blob(id)
    rescue URI::InvalidURIError
      @logger.warn "Invalid URI for #{source}"
      nil
    end

    def find_service_url_for_blob(blob_id)
      Rails.application.routes.url_helpers.rails_blob_path(ActiveStorage::Blob.find(blob_id), only_path: true)
    end

    def nokogiri_will_wrap_with_p?(content)
      !content.start_with?("<")
    end
  end
end
