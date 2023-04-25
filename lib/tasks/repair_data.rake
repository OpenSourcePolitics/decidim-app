# frozen_string_literal: true

namespace :decidim do
  namespace :repair do
    desc "Check for nicknames that doesn't respect valid format and update them, if needed force update with REPAIR_NICKNAME_FORCE=1"
    # TODO: Extract to a lib
    task nickname: :environment do
      logger = Logger.new($stdout)
      logger.info("Checking all nicknames...")

      updates = Decidim::RepairNicknameService.run

      if updates.blank?
        logger.info("No users updated")
      else
        logger.info("#{updates.count} users updated")
        logger.info("Updated users ID : #{updates.join(', ')}")
      end

      logger.info("Operation terminated")
    end
  end
end