# frozen_string_literal: true

module Decidim
  class CreateAdmin
    def self.create!(env)
      params = {
        organization: env_organization_or_first(env["organization_id"]),
        name: env["name"],
        nickname: env["nickname"],
        email: env["email"],
        password: env["password"]
      }

      missing = params.select { |_k, v| v.nil? }.keys

      raise "Missing parameters: #{missing.join(", ")}" unless missing.empty?

      Decidim::User.create!(params.merge({ tos_agreement: "1", admin: true }))
    end

    def self.env_organization_or_first(organization_id)
      Decidim::Organization.find(organization_id)
    rescue ActiveRecord::RecordNotFound
      Decidim::Organization.first
    end
  end
end
