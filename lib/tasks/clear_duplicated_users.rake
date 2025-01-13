# frozen_string_literal: true

namespace :decidim do
  desc "Clear duplicated users with the same phone_numbers in the database"
  task clear_duplicated_users: :environment do
    include Decidim::Logging

    ClearDuplicatedHalfSignupUsersJob.perform_now
  end
end
