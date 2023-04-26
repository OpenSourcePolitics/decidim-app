# frozen_string_literal: true

module Decidim
  class CreateSystemAdmin
    def self.create!(env)
      params = {
        email: env["email"],
        password: env["password"]
      }

      missing = params.select { |_k, v| v.nil? }.keys

      raise "Missing parameters: #{missing.join(", ")}" unless missing.empty?

      Decidim::System::Admin.create!(email: params[:email],
                                     password: params[:password],
                                     password_confirmation: params[:password])
    end
  end
end
