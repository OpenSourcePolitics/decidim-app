# frozen_string_literal: true

module CustomFieldsExtends
  extend ActiveSupport::Concern

  included do
    private

    def parse_xml(xml)
      @xml = xml
      @data = Nokogiri.HTML(@xml).xpath("//dl/dd")
      return if @data.present?

      apply_to_first_textarea
    end
  end
end

Decidim::DecidimAwesome::CustomFields.include(CustomFieldsExtends)
