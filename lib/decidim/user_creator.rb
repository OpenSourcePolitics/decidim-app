# frozen_string_literal: true

module Decidim
  class UserCreator
    def initialize(attributes)
      @attributes = attributes
    end

    def create!
      missing = @attributes.select { |_k, v| v.nil? }.keys

      raise "Missing parameters: #{missing.join(", ")}" unless missing.empty?
    end
  end
end
