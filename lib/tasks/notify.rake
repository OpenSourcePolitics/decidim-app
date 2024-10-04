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

      users = []
      errors = []
      
      csv_file_path = ENV["CSV_FILE"].presence
      
      if csv_file_path.present?
        logger.warn "Rake(#{task_scope.join(":")})> loading CSV file #{csv_file_path}"
        csv_file = CSV.read(csv_file_path, headers: true)
        logger.warn "Rake(#{task_scope.join(":")})> CSV file has #{csv_file.size} lines"
        
        csv_file.each_with_index do |csv_row, index|
          row = csv_row.to_h

          if row["id"].to_i.to_s == row["id"]
            user = Decidim::User.find_by(id: row["id"])
            if user.blank?
              logger.warn "Rake(#{task_scope.join(":")})> ERROR line #{index} : user with id #{row["id"]} not found ... trying with email #{row["email"]}"
              user = Decidim::User.find_by(organization: organization, email: row["email"])
              if user.blank?
                logger.warn "Rake(#{task_scope.join(":")})> ERROR line #{index} : user with id #{row["id"]} or email #{row["email"]} not found ... skipping"
                errors.push(row.merge({ error: "line #{index} : user with id #{row["id"]} or email #{row["email"]} not found" }))
                next
              end
            end

            if row["email"] != user.email
              logger.warn "Rake(#{task_scope.join(":")})> ERROR line #{index} : user with id #{row["id"]} and email #{user.email} doesn't match CSV email #{row["email"]} ... skipping"
              errors.push(row.merge({ error: "line #{index} : user with id #{row["id"]} and email #{user.email} doesn't match CSV email #{row["email"]}" }))
              next
            end

            if ::ValidEmail2::Address.new(user.email).valid?
              users.push(user)
            else
              logger.warn "Rake(#{task_scope.join(":")})> ERROR line #{index} with email #{row["email"]} is not valid"
              errors.push(row.merge({ error: "line #{index} with email #{row["email"]} is not valid" }))
              next
            end
          else
            logger.warn "Rake(#{task_scope.join(":")})> ERROR line #{index} with id #{row["id"]} is not an integer"
            errors.push(row.merge({ error: "line #{index} with id #{row["id"]} is not an integer" }))
            next
          end

          logger.warn "Rake(#{task_scope.join(":")})> found #{users.size} users"
        rescue StandardError => e
          logger.warn { "Rake(#{task_scope.join(":")})>  #{e.class}: '#{e.message}'" }
          errors.push(row.merge({ error: "#{e.class}: #{e.message}" }))
          next
        end
      end

      # USERS take priority over CSV_FILE
      user_emails_from_args = ENV["USERS"].presence&.split(",")

      if user_emails_from_args.present?
        logger.warn { "Rake(#{task_scope.join(":")})> Using USERS parameter with emails #{user_emails_from_args}" }
        users = Decidim::User.where(organization: organization, email: user_emails_from_args)
      end

      if users.blank?
        logger.warn { "Rake(#{task_scope.join(":")})> Getting users directly from database" }
        users = Decidim::User.where(organization: organization, admin: false, deleted_at: nil, blocked: [nil, false]).where("email IS NOT NULL AND email != '' AND name != 'Blocked user'")
      end

      logger.warn "Rake(#{task_scope.join(":")})> found #{users.count} users"

      perform = ENV.fetch("PERFORM", "never")
      logger.warn "Rake(#{task_scope.join(":")})> task performing #{perform}"

      processed_users = 0

      file_path = "tmp/#{task_scope.join("-")}--outgoing--mailing-list--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv"
      FileUtils.mkdir_p(File.dirname(file_path))

      CSV.open(file_path, "w") do |csv|
        csv << ["id","name","email"]
        users.each do |user|
          csv << [
            user.id,
            user.name,
            user.email
          ]

          begin 
            case perform
            when "now"
              NotifyMigrationUserJob.perform_now(user)
            when "later"
              NotifyMigrationUserJob.perform_later(user)
            end
          rescue StandardError => e
            logger.warn { "Rake(#{task_scope.join(":")})> #{e.class}: '#{e.message}'" }
            errors.push(row.merge({ error: "#{e.class}: #{e.message}" }))
            next
          end

          processed_users += 1
        end
      end

      logger.warn "Rake(#{task_scope.join(":")})> #{processed_users} processed users"
      logger.warn "Rake(#{task_scope.join(":")})> mailing list exported to #{file_path}"

      if errors.present?
        logger.warn "Rake(#{task_scope.join(":")})> found #{errors.size} errors"
        errors_file_path = "tmp/errors--#{task_scope.join("-")}--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv"
        CSV.open(errors_file_path, "w") do |csv|
          csv << errors.first.keys
          errors.each do |error|
            csv << error.values
          end
        end
        logger.warn "Rake(#{task_scope.join(":")})> error file exported to #{errors_file_path}"
      end

      logger.warn "Rake(#{task_scope.join(":")})> terminated"
    end
  end
end