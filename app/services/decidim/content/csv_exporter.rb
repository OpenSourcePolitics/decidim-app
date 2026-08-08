# frozen_string_literal: true

module Decidim
  module Content
    class CsvExporter < Decidim::Exporters::CSV
      DEFAULT_OPTIONS = {
        serializers: {
          flatten: false,
          private_fields: false
        },
        csv: {
          col_sep: Decidim.default_csv_col_sep
        }
      }.freeze

      def initialize(collection:, serializer: Serializer, **options)
        super(collection, serializer)
        @options = DEFAULT_OPTIONS.merge(options)
      end

      def export(col_sep = options.dig(:csv, :col_sep))
        data = ::CSV.generate(headers:, write_headers: true, col_sep:) do |csv|
          processed_collection.each do |resource|
            csv << headers.map { |header| custom_sanitize(resource[header]) }
          end
        end
        Decidim::Exporters::ExportData.new(data, "csv")
      end

      private

      attr_reader :options

      def serializer_instance(resource)
        if serializer <= Decidim::Content::BaseContentSerializer
          serializer.new(resource, **options[:serializers])
        else
          serializer.new(resource)
        end
      end

      def processed_collection
        @processed_collection ||= collection.map do |resource|
          serialized_data = serializer_instance(resource).run
          serialized_data = options.dig(:serializers, :flatten) ? flatten(serialized_data) : convert_jsonable_attribute(serialized_data)
          serialized_data.deep_dup
        end
      end

      def convert_jsonable_attribute(resource)
        resource.transform_values do |value|
          if value.is_a?(Hash) || value.is_a?(Array)
            JSON.generate(value.compact_blank)
          else
            value
          end
        end
      end
    end
  end
end
