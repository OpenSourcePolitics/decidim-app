# frozen_string_literal: true

require "logger_with_stdout"

namespace :notify do
  namespace :migration do
    task users: :environment do
      host = ENV["ORGANIZATION_HOST"].presence || Decidim::Organization.first.host
      organization = Decidim::Organization.find_by(host: host)
      raise "Organization not found for '#{host}'" unless organization

      task_scope = %w(notify migration users)

      logger = ::LoggerWithStdout.new("log/#{task_scope.join("-")}--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
      logger.warn "Rake(#{task_scope.join(":")})> initializing..."
      logger.warn "Rake(#{task_scope.join(":")})> Organization with host #{organization.host}"

      users = ENV["USERS"].presence&.split(",")
      if users.present?
        users = Decidim::User.where(organization: organization, email: users)
      else
        users = Decidim::User.where(organization: organization, admin: false, deleted_at: nil, blocked: [nil, false]).where("email IS NOT NULL AND email != '' AND name != 'Blocked user'")
      end

      logger.warn "Rake(#{task_scope.join(":")})> found #{users.count} users"

      perform = ENV.fetch("PERFORM", "never")
      logger.warn "Rake(#{task_scope.join(":")})> task performing #{perform}"

      processed_users = 0

      file_path = "tmp/#{task_scope.join("-")}--mailing-list--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv"
      FileUtils.mkdir_p(File.dirname(file_path))

      CSV.open(file_path, "w") do |csv|
        csv << ["id","name","email"]
        users.each do |user|
          csv << [
            user.id,
            user.name,
            user.email
          ]

          case perform
          when "now"
            NotifyMigrationUserJob.perform_now(user)
          when "later"
            NotifyMigrationUserJob.perform_later(user)
          end

          processed_users += 1
        end
      end

      logger.warn "Rake(#{task_scope.join(":")})> #{processed_users} processed users"
      logger.warn "Rake(#{task_scope.join(":")})> mailing list exported to #{file_path}"
      logger.warn "Rake(#{task_scope.join(":")})> terminated"
    end
  end
end