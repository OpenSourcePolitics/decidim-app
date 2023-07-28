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

      schema.each do |model, columns|
        # TODO: Move columns inside records method
        records(model, columns).each do |record|
          puts "Updating #{model}##{record.id}##{column.name}"
          old_content = record.send(column.name)
          new_content = clean_content(record.send(column.name))

          puts "Old content: #{old_content}"
          puts "New content: #{new_content}"

          record.update!(column.name => new_content)
        end
      end
    end

    def clean_content(content)
      content.transform_values do |value|
        Nokogiri::HTML(value).tap do |doc|
          doc.css("a").each do |link|
            next unless link["href"].include?(@endpoint)

            puts "Replacing #{link["href"]} with #{link["href"]}"
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

    # TODO: Chain where clauses
    def records(model, columns)
      columns.map { |col| model.where("#{col.name}::text LIKE ?", "%#{@endpoint}%") }.reduce(&:or)
    end

    def schema
      models.index_with do |model|
        model.columns.select { |column| column.type.in?(COLUMN_TYPES) }
      end
    end

    # @return [Decidim::Models]
    def models
      ActiveRecord::Base.connection.tables.map do |table|
        next unless table.starts_with?("decidim_")

        table.tr("_", "/").classify.safe_constantize
      end.compact
    end

    def blobs
      @blobs ||= ActiveStorage::Blob.pluck(:filename, :id)
    end
  end
end
