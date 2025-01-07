# frozen_string_literal: true

namespace :decidim do
  desc "Clear duplicated users with the same phone_numbers in the database"
  task clear_duplicated_users: :environment do
    include Decidim::Logging

    clear_user_accounts = ENV.fetch("CLEAR_USER_ACCOUNTS", "false") == "true"
    log!("HELP: Run task with env var CLEAR_USER_ACCOUNTS=true to clear Half Signup and Decidim Users phone numbers") unless clear_user_accounts
    ClearDuplicatedHalfSignupUsersJob.perform_now(clear_user_accounts)
  end
end
