# frozen_string_literal: true

module Decidim
  # Looks for any occurence of "@deprecated_endpoint" in every database columns of type COLUMN_TYPES
  # For each field containing @deprecated_endpoint:
  #   - Looks for the current ActiveStorage::Blob with the given filename
  #   - Find the blob's service_url
  #   - Replace the @deprecated_endpoint with the blob's service_url in text
  #   - Update the column
  # Context:
  # After S3 assets migration with rake task "bundle exec rake scaleway:storage:migrate_from_local", every linked documents URL were well updated.
  # However every links added to text fields redirecting to an uploaded file were outdated and still redirects to the old S3 bucket
  class RepairUrlInContentService
    COLUMN_TYPES = [:string, :jsonb, :text].freeze
    DEFAULT_LOGGER = Rails.logger

    # @param [String] deprecated_endpoint
    def self.run(deprecated_endpoint)
      new(deprecated_endpoint).run
    end

    # @param [String] deprecated_endpoint
    def initialize(deprecated_endpoint, logger = nil)
      @logger = logger || DEFAULT_LOGGER
      @deprecated_endpoint = deprecated_endpoint
    end

    def run
      # Find all models that have a column of type string jsonb or text
      # For each model, find all records that have a column of type string jsonb or text
      # For each record, replace all urls contained in content with the new url
      # Save the record
      return false if @deprecated_endpoint.blank?

      models.each do |model|
        model = model.safe_constantize
        next unless model.respond_to?(:columns)

        @logger.info("Checking model #{model} for deprecated endpoints #{@deprecated_endpoint}")
        records = records_for model
        next if records.blank?

        @logger.info "Found #{records.count} records to update for #{model}"
        records.each do |record|
          columns = model.columns.select { |column| column.type.in? COLUMN_TYPES }
          columns.each do |column|
            current_content = record.send(column.name)

            next unless current_content.to_s.include?(@deprecated_endpoint)

            @logger.info "Updating #{model}##{record.id}##{column.name}"
            new_content = clean_content(record.send(column.name))

            @logger.info "Old content: #{current_content}"
            @logger.info "New content: #{new_content}"

            record.update!(column.name => new_content)
          end
        end
      end
    end

    def records_for(model)
      model.columns.map do |col|
        next unless col.type.in?(COLUMN_TYPES)

        model.where("#{col.name}::text LIKE ?", "%#{@deprecated_endpoint}%")
      end.compact.reduce(&:or)
    rescue StandardError => e
      @logger.warn "Error while fetching records from #{model}: #{e.message}"
      []
    end

    # @return [String]
    def models
      ActiveRecord::Base.connection.tables.map do |table|
        next unless table.starts_with?("decidim_")

        table.tr("_", "/").classify
      end.compact
    end

    def blobs
      @blobs ||= ActiveStorage::Blob.pluck(:filename, :id)
    end

    def clean_content(content)
      content.transform_values do |value|
        Nokogiri::HTML(value).tap do |doc|
          doc.css("a").each do |link|
            next unless link["href"].include?(@deprecated_endpoint)

            @logger.info "Replacing #{link["href"]} with #{link["href"]}"
            link["href"] = new_link(link["href"])
          end
        end.css("body").inner_html
      end
    end

    def new_link(link)
      uri = URI.parse(link)
      filename = CGI.parse(uri.query)["response-content-disposition"].first.match(/filename=("?)(.+)\1/)[2]

      _filename, id = blobs.select do |blob, _id|
        ActiveSupport::Inflector.transliterate(blob) == filename
      end.first

      find_service_url_for_blob(id)
    end

    def find_service_url_for_blob(blob_id)
      ActiveStorage::Blob.find(blob_id).service_url
    end
  end
end
