# frozen_string_literal: true

namespace :decidim do
  namespace :repair do
    desc "Check for nicknames that doesn't respect valid format and update them, if needed force update with REPAIR_NICKNAME_FORCE=1"
    task nickname: :environment do
      logger = Logger.new($stdout)
      logger.info("Checking all nicknames...")

      udpated_user_ids = Decidim::RepairNicknameService.run

      if udpated_user_ids.blank?
        logger.info("No users updated")
      else
        logger.info("#{udpated_user_ids.count} users updated")
        logger.info("Updated users ID : #{udpated_user_ids.join(", ")}")
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
        logger.info("Updated comments ID : #{updated_comments_ids.join(",")}")
      end

      logger.info("Operation terminated")
    end

    desc "Add all missing translation for translatable resources"
    task translations: :environment do
      logger = Logger.new($stdout)
      logger.info("Checking all translatable resources...")

      updated_resources_ids = Decidim::RepairTranslationsService.run(logger: logger)

      if updated_resources_ids.blank?
        logger.info("No resources updated")
      else
        logger.info("#{updated_resources_ids.count} resources enqueue for translation")
        logger.info("Enqueued resources : #{updated_resources_ids.join(", ")}")
      end

      logger.info("Operation terminated")
    end

    task url_in_content: :environment do
      deprecated_objectstore_s3_host = ENV["DEPRECATED_OBJECTSTORE_S3_HOST"]

      raise ArgumentError, "DEPRECATED_OBJECTSTORE_S3_HOST env variable is not set" if deprecated_objectstore_s3_host.blank?

      Decidim::RepairUrlInContentService.run(deprecated_objectstore_s3_host)
    end
  end
end
