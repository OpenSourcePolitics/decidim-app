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

    task components: :environment do
      host = ENV["ORGANIZATION_HOST"].presence || Decidim::Organization.first.host
      organization = Decidim::Organization.find_by(host: host)
      raise "Organization not found for '#{host}'" unless organization

      logger = ::LoggerWithStdout.new("log/clean-bdx-components--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
      logger.warn "Rake(clean:bdx:components)> initializing..."
      logger.warn "Rake(clean:bdx:components)> Organization with host #{organization.host}"

      processes_counter = 0
      components_counter = 0

      Decidim::ParticipatoryProcess.where(organization: organization).each do |process|

        if process.slug.start_with?("projet-")

          meetings_component = Decidim::Component.where(manifest_name: "meetings", participatory_space: process)
          
          if meetings_component.count == 2
            meetings_component.first.update_columns(published_at: DateTime.now)
            Decidim::Meetings::Meeting.where(component: meetings_component.second).update_all(decidim_component_id: meetings_component.first.id)
            meetings_component.second.update_columns(published_at: nil)
            logger.warn "Rake(clean:bdx:components)> meetings component https://#{organization.host}/participatory_processes/#{process.slug}/components/#{meetings_component.second.id}/manage/ unpublished ..."
            components_counter += 1
          end
          meetings = Decidim::Meetings::Meeting.where(component: meetings_component).order("id ASC")
          meetings.each do |meeting|
            if Decidim::Meetings::Meeting.find(meeting.id).published?
              Decidim::Meetings::Meeting.where(component: meetings_component, title: meeting.title, description: meeting.description, start_time: meeting.start_time).where.not(id: meeting.id).update_all(published_at: nil)
            end
          end

          pages_component = Decidim::Component.where(manifest_name: "pages", participatory_space: process)

          if pages_component.count == 2
            pages_component.first.update_columns(published_at: DateTime.now)
            pages_component.second.update_columns(published_at: nil)
            logger.warn "Rake(clean:bdx:components)> pages component https://#{organization.host}/participatory_processes/#{process.slug}/components/#{pages_component.second.id}/manage/ unpublished ..."
            components_counter += 1
          end

          proposals_component = Decidim::Component.where(manifest_name: "proposals", participatory_space: process)

          if proposals_component.count == 2
            proposals_component.first.update_columns(published_at: DateTime.now)
            Decidim::Proposals::Proposal.where(component: proposals_component.second).update_all(decidim_component_id: proposals_component.first.id)
            proposals_component.second.update_columns(published_at: nil)
            logger.warn "Rake(clean:bdx:components)> proposals component https://#{organization.host}/participatory_processes/#{process.slug}/components/#{proposals_component.second.id}/manage/ unpublished ..."
            components_counter += 1
          end
        end

        processes_counter += 1
      end

      logger.warn "Rake(clean:bdx:components)> #{processes_counter} participatory processes were analyzed"
      logger.warn "Rake(clean:bdx:components)> #{components_counter} components where updated"
      logger.warn "Rake(clean:bdx:components)> terminated"


    end   

    task files: :environment do
      host = ENV["ORGANIZATION_HOST"].presence || Decidim::Organization.first.host
      organization = Decidim::Organization.find_by(host: host)
      raise "Organization not found for '#{host}'" unless organization

      logger = ::LoggerWithStdout.new("log/clean-bdx-files--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
      logger.warn "Rake(clean:bdx:files)> initializing..."
      logger.warn "Rake(clean:bdx:files)> Organization with host #{organization.host}"

      processes_counter = 0
      deleted_files_counter = 0
      errors_counter = 0

      Decidim::ParticipatoryProcess.where(organization: organization).where("slug LIKE 'projet-%'").each do |process|

        if process.attachments.present?
          logger.warn "Rake(clean:bdx:files)> Found #{process.attachments.count} attachments found for process #{process.id} | #{process.slug} | https://#{organization.host}/admin/participatory_processes/#{process.slug}/attachments"

          deleted_process_files_counter = 0
          process_errors_counter = 0
          attachments_titles = []

          process.attachments.each do |attachment|
            if attachments_titles.include?({ title: attachment.title, filename: attachment.file&.blob&.filename })
              begin
                attachment.destroy
                logger.warn { "Rake(clean:bdx:files)> File #{attachment.id} | #{attachment.title} deleted" }
                deleted_process_files_counter += 1
                deleted_files_counter += 1
              rescue StandardError => e
                logger.error { "Rake(clean:bdx:files)> ERROR on file #{attachment.id} | #{attachment.title} | https://#{organization.host}/admin/participatory_processes/#{process.slug}/attachments/#{attachment.id}/edit --> #{e.class}: '#{e.message}'" }
                process_errors_counter += 1
                errors_counter += 1
                next
              end
            else 
              attachments_titles.push({ title: attachment.title, filename: attachment.file&.blob&.filename })
            end
          end

          logger.warn { "Rake(clean:bdx:files)> #{deleted_process_files_counter} files were deleted on process #{process.slug}" }
          logger.warn { "Rake(clean:bdx:files)> with #{process_errors_counter} errors" }

        else
          logger.warn "Rake(clean:bdx:files)> No attachments found for process #{process.id} | #{process.slug} | https://#{organization.host}/admin/participatory_processes/#{process.slug}/attachments"
        end
        processes_counter += 1
      end

      logger.warn "Rake(clean:bdx:files)> #{processes_counter} participatory processes were analyzed"
      logger.warn "Rake(clean:bdx:files)> #{deleted_files_counter} files where deleted"
      logger.warn "Rake(clean:bdx:files)> #{errors_counter} errors were detected"
      logger.warn "Rake(clean:bdx:files)> terminated"
    end
  end
end
