# frozen_string_literal: true

require "active_support/concern"

module ResultExtends
  extend ActiveSupport::Concern
  included do
    include Decidim::Reportable
  end
end

Decidim::Accountability::Result.include(ResultExtends)
