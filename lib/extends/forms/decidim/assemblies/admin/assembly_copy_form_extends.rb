# frozen_string_literal: true

require "active_support/concern"

module AssemblyDuplicateFormExtends
  extend ActiveSupport::Concern

  included do
    attribute :copy_landing_page_blocks, Decidim::AttributeObject::TypeMap::Boolean
  end
end

Decidim::Assemblies::Admin::AssemblyDuplicateForm.include(AssemblyDuplicateFormExtends)
