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
  end
end
