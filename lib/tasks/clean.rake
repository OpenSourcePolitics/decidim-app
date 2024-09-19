# frozen_string_literal: true

require "ruby-progressbar"
require "logger_with_stdout"

namespace :clean do
  namespace :bdx do
    task spam_users: :environment do
      host = ENV["ORGANIZATION_HOST"].presence || Decidim::Organization.first.host
      organization = Decidim::Organization.find_by(host: host)
      raise "Organization not found for '#{host}'" unless organization

      limit = ENV["LIMIT"].presence

      perform_now = ENV["PERFORM_NOW"].presence

      if perform_now
        DrupalCleanSpamUsersJob.perform_now(organization: organization, limit: limit)
      else
        DrupalCleanSpamUsersJob.perform_later(organization: organization, limit: limit)
      end
    end
  end
end
