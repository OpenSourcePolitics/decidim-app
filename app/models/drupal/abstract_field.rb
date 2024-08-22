# frozen_string_literal: true

require "composite_primary_keys"

module Drupal
  class AbstractField < AbstractRecord
    self.abstract_class = true
  end
end
