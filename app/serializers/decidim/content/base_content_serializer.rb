# frozen_string_literal: true

module Decidim
  module Content
    class BaseContentSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      attr_reader :options

      def initialize(resource, **options)
        super(resource)
        @options = options
      end

      def serialize
        {
          uid: uid(resource)
        }.merge(super.with_indifferent_access.except(:id))
      end

      def include_private_fields?
        options.dig(:serializers, :private_fields)
      end
    end
  end
end
