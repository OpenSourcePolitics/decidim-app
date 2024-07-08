# frozen_string_literal: true

module Drupal
  class AbstractRecord < ApplicationRecord
    self.abstract_class = true
    establish_connection :drupal
  end
end
