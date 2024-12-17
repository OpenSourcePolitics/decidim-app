# frozen_string_literal: true

require "active_support/concern"

module CommentFormExtends
  extend ActiveSupport::Concern

  included do
    attribute :current_component, Decidim::Component

    validates :current_component, presence: true
  end
end

Decidim::Comments::CommentForm.include(CommentFormExtends)
