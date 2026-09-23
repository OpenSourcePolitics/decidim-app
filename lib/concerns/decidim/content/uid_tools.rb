# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Content
    module UidTools
      extend ActiveSupport::Concern
      included do
        def uid(resource)
          resource.to_gid.uri.path.underscore.parameterize(separator: "--").dasherize if resource.respond_to?(:to_gid) && resource.try(:id).present?
        end

        def locate_resource_by_uid(uid)
          exploded = uid.split("--")
          id = exploded.pop.to_i
          model_name = exploded.map(&:underscore).map(&:camelize).join("::")
          model_name.constantize.find(id)
        end

        def polymorphic_uid(resource, key)
          return if key.blank?

          type_attribute = "#{key}_type".to_sym
          id_attribute = "#{key}_id".to_sym
          return unless resource.respond_to?(type_attribute) && resource.respond_to?(id_attribute)

          # Rails.logger.debug { "polymorphic_uid: resource=#{resource.class.name} key=#{key} type=#{resource.try(type_attribute)} id=#{resource.try(id_attribute)}" }
          uid(resource.try(type_attribute)&.safe_constantize&.new(id: resource.try(id_attribute)&.to_i))
        end
      end
    end
  end
end
