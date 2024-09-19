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

    task old_users: :environment do
      host = ENV["ORGANIZATION_HOST"].presence || Decidim::Organization.first.host
      organization = Decidim::Organization.find_by(host: host)
      raise "Organization not found for '#{host}'" unless organization

      limit = ENV["LIMIT"].presence

      logger = ::LoggerWithStdout.new("log/clean-bdx-old_users--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
      logger.warn "Rake(clean:bdx:old_users)> initializing..."
      logger.warn "Rake(clean:bdx:old_users)> Organization with host #{organization.host}"
      logger.warn("Rake(clean:bdx:old_users)> limit is #{limit}") if limit

      old_users_counter = 0

      Decidim::User.where("extended_data::jsonb ? :key", key: "drupal").limit(limit).each do |user|

        next if user.deleted?
        next if user.extended_data.dig("drupal", "uid") == 0

        last_active_date = user.extended_data.dig("drupal", "login")&.to_datetime
        last_active_date = user.extended_data.dig("drupal", "created")&.to_datetime if last_active_date == "1970-01-01T01:00:00.000+01:00".to_datetime

        if last_active_date < (DateTime.now - 3.years)

          profile_data = {
            drupal: user.extended_data["drupal"].merge(
              {
                name: user.name,
                mail: user.email,
                old: true
              }
            )
          }

          user.name = ""
          user.nickname = ""
          user.email = ""
          user.delete_reason = "drupal import clean old account"
          user.admin = false if user.admin?
          user.deleted_at = Time.current
          user.skip_reconfirmation!
          user.avatar.purge
          user.save!
    
          user.identities.destroy_all

          logger.warn "Rake(clean:bdx:spam_users)> Decidim user #{user.id} / #{profile_data.dig(:drupal, :mail)} with last active date #{last_active_date} was anonymized"

          user.extended_data = user.extended_data.merge(profile_data)
          user.save!(validate: false)

          old_users_counter += 1
        end
      end

      logger.warn "Rake(clean:bdx:old_users)> #{old_users_counter} users from drupal were deleted (anonymized)"
      logger.warn "Rake(clean:bdx:old_users)> terminated"


    end
  end
end
