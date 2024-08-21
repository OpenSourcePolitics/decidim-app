# frozen_string_literal: true

namespace :authorizations do
  task export_to_user_extended_data: :environment do
    name = ENV["AUTHORIZATION_HANDLE_NAME"].presence
    raise "AUTHORIZATION_HANDLE_NAME is blank." if name.blank?

    raise "No data found for authorization handler name '#{name}'" unless Decidim::Authorization.exists?(name: name)

    AuthorizationDataToUserDataJob.perform_later(name: name)
  end
end
