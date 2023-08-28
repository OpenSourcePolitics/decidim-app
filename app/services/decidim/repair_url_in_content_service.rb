# frozen_string_literal: true

require "decidim/content_fixer"

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
    # @param [Logger] logger
    def self.run(deprecated_endpoint, logger = nil)
      new(deprecated_endpoint, logger).run
    end

    # @param [String] deprecated_endpoint
    # @param [Logger] logger
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

    # In some cases, the column returns a settings object,
    # therefore we need to update each of its attributes before saving the column
    # @param [Object] record
    # @param [[ActiveRecord::ConnectionAdapters::PostgreSQL::Column]] columns
    # @return record | nil
    def update_each_column(record, columns)
      columns.each do |column|
        current_content = current_content_for(record, column)
        next if current_content.blank?

        column_name = column.try(:name) ? column.name : column

        @logger.info "Updating ##{[record.class, record.try(:id), column_name].compact.join("# ")}"

        if current_content.is_a?(Hash) || current_content.is_a?(Array) || current_content.is_a?(String)
          next unless current_content.to_s.include?(@deprecated_endpoint)

          new_content = Decidim::ContentFixer.repair(current_content, @deprecated_endpoint, @logger)

          @logger.info "Old content: #{current_content}"
          @logger.info "New content: #{new_content}"

          write_attribute(record, column, new_content)
        else
          # If the column is a settings object, we need to update each of its attributes using a recursive call
          write_attribute(record, column, update_each_column(current_content, current_content.instance_variables))
        end
      end

      record
    end

    def write_attribute(record, column, value)
      if column.try(:name) && record.respond_to?(:"#{column.name}=")
        record.write_attribute(:"#{column.name}", value)
      else
        record.instance_variable_set(column, value)
      end
    end

    def current_content_for(record, column)
      if column.try(:name) && record.respond_to?(column.name)
        record.send(column.name)
      else
        record.instance_variable_get(column)
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

    def models
      ActiveRecord::Base.connection.tables.map do |table|
        next unless table.starts_with?("decidim_")

        classify_model(table)
      end.compact
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
