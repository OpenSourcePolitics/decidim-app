# frozen_string_literal: true

module Decidim
  class RepairUrlInContentService
    COLUMN_TYPES = [:string, :jsonb, :text].freeze
    OLD_URL = "https://villeurbanne-prod-storage.s3.fr-par.scw.cloud"

    def self.run
      new.run
    end

    def run
      # Find all models that have a column of type string jsonb or text
      # For each model, find all records that have a column of type string jsonb or text
      # For each record, replace all urls contained in content with the new url
      # Save the record

      schema.each do |model, columns|
        columns.each do |column|
          records(model, column).each do |record|
            puts "Updating #{model}##{record.id}##{column.name}"
            old_content = record.send(column.name)
            new_content = clean_content(record.send(column.name))

            puts "Old content: #{old_content}"
            puts "New content: #{new_content}"

            record.update!(column.name => new_content)
          end
        end
      end
    end

    def clean_content(content)
      content.transform_values do |value|
        Nokogiri::HTML(value).tap do |doc|
          doc.css("a").each do |link|
            next unless link["href"].include?(OLD_URL)

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

    def records(model, column)
      model.where("#{column.name}::text LIKE ?", "%#{OLD_URL}%")
    end

    def schema
      models.index_with do |model|
        model.columns.select { |column| COLUMN_TYPES.include?(column.type) }
      end
    end

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
