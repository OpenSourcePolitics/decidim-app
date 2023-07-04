# frozen_string_literal: true

require "decidim/user_creator"

module Decidim
  class AdminCreator < Decidim::UserCreator
    def self.create!(env)
      new({ organization: env_organization_or_first(env["organization_id"]),
            name: env["name"],
            nickname: env["nickname"],
            email: env["email"],
            password: env["password"] }).create!
    end

    def create!
      super

      Decidim::User.find_or_initialize_by(email: @attributes[:email])
                   .update!(@attributes.merge({ tos_agreement: "1", admin: true }))
    end

    def self.env_organization_or_first(organization_id)
      Decidim::Organization.find(organization_id)
    rescue ActiveRecord::RecordNotFound
      Decidim::Organization.first
    end
  end
end
