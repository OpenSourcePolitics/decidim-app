# frozen_string_literal: true

module Decidim
  # Looks for any occurence of "@endpoint" in every database columns of type COLUMN_TYPES
  # For each field containing @endpoint:
  #   - Looks for the current ActiveStorage::Blob with the given filename
  #   - Find the blob's service_url
  #   - Replace the @endpoint with the blob's service_url in text
  #   - Update the column
  # Context:
  # After S3 assets migration with rake task "bundle exec rake scaleway:storage:migrate_from_local", every linked documents URL were well updated.
  # However every links added to text fields redirecting to an uploaded file were outdated and still redirects to the old S3 bucket
  class RepairUrlInContentService
    COLUMN_TYPES = [:string, :jsonb, :text].freeze

    # @param [String] endpoint
    def self.run(endpoint)
      new(endpoint).run
    end

    # @param [String] endpoint
    def initialize(endpoint)
      @endpoint = endpoint
    end

    def run
      # Find all models that have a column of type string jsonb or text
      # For each model, find all records that have a column of type string jsonb or text
      # For each record, replace all urls contained in content with the new url
      # Save the record
      return false if @endpoint.blank?

      models.each do |model|
        records_for(model).each do |record|
          Rails.application.logger :info, "Updating #{model}##{record.id}##{column.name}"
          old_content = record.send(column.name)
          new_content = clean_content(record.send(column.name))

          Rails.application.logger :info, "Old content: #{old_content}"
          Rails.application.logger :info, "New content: #{new_content}"

          record.update!(column.name => new_content)
        end
      end
    end

    def records_for(model)
      model = model.safe_constantize
      return [] unless model.respond_to?(:columns)

      model.columns.map do |col|
        next unless col.type.in?(COLUMN_TYPES)

        model.where("#{col.name}::text LIKE ?", "%#{@endpoint}%")
      end.compact.reduce(&:or)
    rescue StandardError => e
      Rails.application.logger.warn "Error while updating #{model}: #{e.message}"
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
            next unless link["href"].include?(@endpoint)

            Rails.application.logger :info, "Replacing #{link["href"]} with #{link["href"]}"
            link["href"] = new_link(link["href"])
          end
        end.css("body").inner_html
      end
    end

    def new_link(link)
      uri = URI.parse(link)
      filename = CGI.parse(uri.query)["response-content-disposition"].first.match(/filename=("?)(.+)\1/)[2]

      _file_name, id = blobs.select do |blob, _id|
        ActiveSupport::Inflector.transliterate(blob) == filename
      end.first

      ActiveStorage::Blob.find(id).service_url
    end
  end
end
