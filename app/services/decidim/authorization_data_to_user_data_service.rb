# frozen_string_literal: true

module Decidim
  class AuthorizationDataToUserDataService
    def self.run(**args)
      new(**args).execute
    end

    def initialize(**args)
      @name = args[:name]
      @user = args[:user]
    end

    def execute
      Decidim::Authorization.find_each(filter) do |authorization|
        authorization.user.update(extended_data: authorization.user.extended_data.merge({ @name.to_s => authorization.metadata }))
      end
    end

    def filter
      @filter ||= {
        name: @name,
        user: @user
      }.compact
    end
  end
end
