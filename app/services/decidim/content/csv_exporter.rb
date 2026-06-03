# frozen_string_literal: true

module Decidim
  module Content
    class CsvExporter < Decidim::Exporters::CSV
      DEFAULT_OPTIONS = {
        flatten: false,
        csv_options: {
          col_sep: Decidim.default_csv_col_sep
        }
      }.freeze

      def initialize(collection:, serializer: Serializer, **options)
        super(collection, serializer)
        @options = DEFAULT_OPTIONS.merge(options)
      end

      def export(col_sep = options.dig(:csv_options, :col_sep))
        data = ::CSV.generate(headers:, write_headers: true, col_sep:) do |csv|
          processed_collection.each do |resource|
            csv << headers.map { |header| custom_sanitize(resource[header]) }
          end
        end
        Decidim::Exporters::ExportData.new(data, "csv")
      end

      private

      attr_reader :options

      def processed_collection
        @processed_collection ||= collection.map do |resource|
          serialized_data = serializer.new(resource).run
          serialized_data = options[:flatten] ? flatten(serialized_data) : convert_jsonable_atribute(serialized_data)
          serialized_data.deep_dup
        end
      end

      def convert_jsonable_atribute(resource)
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
