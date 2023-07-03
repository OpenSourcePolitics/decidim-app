# frozen_string_literal: true

require "decidim/user_creator"

module Decidim
  class SystemAdminCreator < Decidim::UserCreator
    def self.create!(env)
      new({ email: env["email"], password: env["password"] }).create!
    end

    def create!
      super

      Decidim::System::Admin.find_or_initialize_by(email: @attributes[:email])
                            .update!(@attributes)
    end
  end
end
