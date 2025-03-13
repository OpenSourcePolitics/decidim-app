# frozen_string_literal: true

namespace :decidim do
  namespace :repair do
    desc "Check for nicknames that doesn't respect valid format and update them, if needed force update with REPAIR_NICKNAME_FORCE=1"
    task nickname: :environment do
      logger = Logger.new($stdout)
      logger.info("Checking all nicknames...")

      updated_user_ids = Decidim::RepairNicknameService.run

      if updated_user_ids.blank?
        logger.info("No users updated")
      else
        logger.info("#{updated_user_ids.count} users updated")
        logger.info("Updated users ID : #{updated_user_ids.join(", ")}")
      end

      logger.info("Operation terminated")
    end

    desc "Check for malformed comments body and repair them if needed"
    task comments: :environment do
      logger = Logger.new($stdout)
      logger.info("Checking all comments...")

      updated_comments_ids = Decidim::RepairCommentsService.run

      if updated_comments_ids.blank?
        logger.info("No comments updated")
      else
        logger.info("#{updated_comments_ids} comments updated")
        logger.info("Updated comments ID : #{updated_comments_ids.join(", ")}")
      end

      logger.info("Operation terminated")
    end

    desc "Add all missing translation for translatable resources"
    task translations: :environment do
      logger = Logger.new($stdout)
      if Decidim.enable_machine_translations
        logger.info("Checking all translatable resources...")

        updated_resources_ids = Decidim::RepairTranslationsService.run(logger: logger)

        if updated_resources_ids.blank?
          logger.info("No resources updated")
        else
          logger.info("#{updated_resources_ids.count} resources enqueue for translation")
          logger.info("Enqueued resources : #{updated_resources_ids.join(", ")}")
        end

        logger.info("Operation terminated")
      else
        logger.warn("Machine translation is not enabled")
      end
    end

    desc 'Replaces "@deprecated_endpoint" in every database columns with the right blob URL'
    task url_in_content: :environment do
      logger = Logger.new($stdout)
      deprecated_hosts = ENV["DEPRECATED_OBJECTSTORE_S3_HOSTS"].to_s.split(",").map(&:strip)

      if deprecated_hosts.blank?
        logger.warn("DEPRECATED_OBJECTSTORE_S3_HOSTS env variable is not set")
      else
        deprecated_hosts.each do |host|
          Decidim::RepairUrlInContentService.run(host, logger)
        end
      end
    end

    desc "Correct locales depth for proposals"
    task proposals_locales: :environment do
      total = Decidim::Proposals::Proposal.count
      Rails.logger.warn("(decidim:repair:proposals_locales) > Checking locales for #{total} proposals...")
      updated = 0
      Decidim::Proposals::Proposal.find_each do |proposal|
        title = proposal.title
        body = proposal.body
        new_title = {}
        new_body = {}

        Decidim.available_locales.map(&:to_s).each do |locale|
          new_title[locale] = title[locale] if title[locale].present? && title[locale].is_a?(String)
          new_title[locale] = title[locale].values.first if title[locale].present? && title[locale].is_a?(Hash)
          new_body[locale] = body[locale] if body[locale].present? && body[locale].is_a?(String)
          new_body[locale] = body[locale].values.first if body[locale].present? && body[locale].is_a?(Hash)
        end

        proposal.title = new_title if new_title.present?
        proposal.body = new_body if new_body.present?
        if proposal.changed?
          updated += 1
          proposal.save(validate: false)
        end
      end
      Rails.logger.warn("(decidim:repair:proposals_locales) > Updated #{updated} proposals")
    end

    desc "Correct locales depth for comments"
    task comments_locales: :environment do
      total = Decidim::Comments::Comment.count
      Rails.logger.info("(decidim:repair:comments_locales) > Checking locales for #{total} comments...")
      updated = 0
      Decidim::Comments::Comment.find_each do |comment|
        body = comment.body
        new_body = {}

        Decidim.available_locales.map(&:to_s).each do |locale|
          new_body[locale] = body[locale] if body[locale].present? && body[locale].is_a?(String)
          new_body[locale] = body[locale].values.first if body[locale].present? && body[locale].is_a?(Hash)
        end

        comment.body = new_body if new_body.present?
        if comment.changed?
          updated += 1
          comment.save(validate: false)
        end
      end
      Rails.logger.info("(decidim:repair:comments_locales) > Updated #{updated} comments")
    end
  end
end
