# frozen_string_literal: true

module Drupal
  class User < AbstractRecord
    self.table_name = "users"

    def self.instance_method_already_implemented?(method_name)
      return true if %w(changed changed?).include? method_name

      super
    end
  end
end
