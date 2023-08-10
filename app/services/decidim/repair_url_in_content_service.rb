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

    # @param [String] deprecated_endpoint
    # @param [ActiveSupport::Logger] logger
    def self.run(deprecated_endpoint, logger = nil)
      new(deprecated_endpoint, logger).run
    end

    # @param [String] deprecated_endpoint
    # @param [ActiveSupport::Logger] logger
    def initialize(deprecated_endpoint, logger = nil)
      @logger = logger || Rails.logger
      @deprecated_endpoint = deprecated_endpoint&.gsub(%r{https?://}, "")
    end

    def run
      # Find all models that have a column of type string jsonb or text
      # For each model, find all records that have a column of type string jsonb or text
      # For each record, replace all urls contained in content with the new url
      # Save the record
      return false if @deprecated_endpoint.blank?

      models.each do |model|
        next unless model.respond_to?(:columns)

        @logger.info("Checking model #{model} for deprecated endpoints #{@deprecated_endpoint}")
        records = records_for model
        next if records.blank?

        @logger.info "Found #{records.count} records to update for #{model}"
        records.each do |record|
          columns = model.columns.select { |column| column.type.in? COLUMN_TYPES }
          record = update_each_column(record, columns)

          save_record!(record)
        end
      end
    end

    def save_record!(record)
      if record.invalid?
        @logger.warn "Invalid record #{record.class}##{record.id}: #{record.errors.full_messages.join(", ")}"
        return
      end

      if record.has_changes_to_save?
        record.class.transaction do
          record.save!
        end
      else
        @logger.info "No changes to save for #{record.class}##{record.id}"
      end
    end

    # @param [Object] record
    # @param [[ActiveRecord::ConnectionAdapters::PostgreSQL::Column]] columns
    # @return record | nil
    def update_each_column(record, columns)
      columns.each do |column|
        current_content = record.send(column.name)
        next unless current_content.to_s.include?(@deprecated_endpoint)

        @logger.info "Updating ##{record.class}##{record.id}.#{column.name}"
        new_content = clean_content(record.send(column.name))

        @logger.info "Old content: #{current_content}"
        @logger.info "New content: #{new_content}"

        if new_content.to_s.include?(@deprecated_endpoint)
          @logger.warn "New content '#{record.class}##{record.id}.#{column.name}' still contains deprecated endpoint #{@deprecated_endpoint}"
          next
        end

        record.write_attribute(:"#{column.name}", new_content)
      end

      record
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

    def models
      ActiveRecord::Base.connection.tables.map do |table|
        next unless table.starts_with?("decidim_")

        classify_model(table)
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

            new_link = new_link(link["href"])

            next unless new_link

            @logger.info "Replacing #{link["href"]} with #{new_link}"
            link["href"] = new_link
          end
        end.css("body").inner_html
      end
    end

    def new_link(link)
      uri = URI.parse(link)
      filename = CGI.parse(uri.query)["response-content-disposition"].first.match(/filename=("?)(.+)\1/)[2]
      _filename, id = blobs.select { |blob, _id| ActiveSupport::Inflector.transliterate(blob) == filename }.first

      find_service_url_for_blob(id)
    end

    def find_service_url_for_blob(blob_id)
      ActiveStorage::Blob.find(blob_id).service_url
    rescue URI::InvalidURIError
      @logger.warn "Invalid URI for blob #{blob_id}"
      nil
    end

    # Because of the way decidim models are named, we need to try to find the model by subbing _ with / and then classify it
    # For example "decidim_comments_comments" becomes "Decidim::CommentsComment", then "Decidim::Comments::Comment"
    # This helps us find models that are namespaced
    # @param [String] table
    def classify_model(table)
      if table.include?("_")
        new_table = table.sub("_", "/")
        model = new_table.classify.safe_constantize

        return model if model

        classify_model(new_table)
      else
        @logger.warn "Could not find model for table #{table}"

        nil
      end
    end
  end
end
