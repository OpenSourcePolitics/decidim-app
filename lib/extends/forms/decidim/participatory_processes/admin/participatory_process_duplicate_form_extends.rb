# frozen_string_literal: true

require "active_support/concern"

module ParticipatoryProcessDuplicateFormExtends
  extend ActiveSupport::Concern

  included do
    attribute :copy_landing_page_blocks, Decidim::AttributeObject::TypeMap::Boolean
  end
end

Decidim::ParticipatoryProcesses::Admin::ParticipatoryProcessDuplicateForm.include(ParticipatoryProcessDuplicateFormExtends)
