# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Content
    module UidTools
      extend ActiveSupport::Concern
      included do
        def uid(resource)
          resource.to_gid.uri.path.underscore.parameterize(separator: "--").dasherize if resource.respond_to?(:to_gid)
        end

        def locate_resource_by_uid(uid)
          exploded = uid.split("--")
          id = exploded.pop.to_i
          model_name = exploded.map(&:underscore).map(&:camelize).join("::")
          model_name.constantize.find(id)
        end
      end
    end
  end
end
