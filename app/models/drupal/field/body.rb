# frozen_string_literal: true

module Drupal
  module Field
    class Body < ::Drupal::AbstractField
      self.table_name = "field_data_comment_body"
    end
  end
end
