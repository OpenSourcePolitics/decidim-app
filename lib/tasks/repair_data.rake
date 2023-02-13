# frozen_string_literal: true

namespace :decidim do
  namespace :repair do
    desc "Check for nicknames that doesn't respect valid format and update them, if needed force update with REPAIR_NICKNAME_FORCE=1"
    task nickname: :environment do
      logger = logger(Rails.env)
      logger.info("[decidim:repair:nickname] :: Checking all nicknames...")
      invalid_users = Decidim::User.where.not("nickname ~* ?", "^[\\w-]+$")

      if invalid_users.blank?
        logger.info("[decidim:repair:nickname] :: All nicknames seems to be valid")
        logger.info("[decidim:repair:nickname] :: Operation terminated")
      else
        logger.info("[decidim:repair:nickname] :: Found #{invalid_users.count} invalids nicknames")
        logger.info("[decidim:repair:nickname] :: Invalid user IDs : [#{invalid_users.map(&:id).join(", ")}]")

        updated_users = []
        invalid_users.each do |user|
          chars = []

          user.nickname.codepoints.each do |ascii_code|
            char = ascii_to_valid_char(ascii_code)
            chars << char if char.present?
          end

          new_nickname = chars.join.downcase
          logger.info("[decidim:repair:nickname] :: User (##{user.id}) renaming nickname from '#{user.nickname}' to '#{new_nickname}'")
          user.nickname = new_nickname

          updated_users << user
        end

        if ask_for_permission(logger, updated_users.count)
          logger.info("[decidim:repair:nickname] :: Updating users...")
          updated_users.each do |user|
            user.save!
            logger.info("[decidim:repair:nickname] :: User (##{user.id}) successfully updated")
          rescue ActiveRecord::RecordInvalid => e
            logger.error("[decidim:repair:nickname] :: User (##{user.id}) failed to update : #{e.message}")
            logger.error("[decidim:repair:nickname] :: Trying with a another nickname: #{user.nickname}-#{user.id}")
            user.nickname = "#{user.nickname}#{user.id}"
            user.save!
          rescue StandardError => e
            logger.error("[decidim:repair:nickname] :: User (##{user.id}) an error occured")
            logger.error("[decidim:repair:nickname] :: #{e}")
          end
        else
          logger.info("[decidim:repair:nickname] :: Operation terminated")
        end
      end
    end
  end
end

def logger(env)
  if env == "production"
    Logger.new($stdout)
  else
    Rails.logger
  end
end

def ask_for_permission(logger, users_count)
  logger.info("[decidim:repair:nickname] :: Do you want to update these #{users_count} users ?")
  return true if ENV["REPAIR_NICKNAME_FORCE"] == "1"

  logger.info("[decidim:repair:nickname] :: prepend REPAIR_NICKNAME_FORCE=1 to your command to update")

  false
end

def ascii_to_valid_char(id)
  letters = ("A".."Z").to_a.join("").codepoints
  letters += ("a".."z").to_a.join("").codepoints
  digits = ("0".."9").to_a.join("").codepoints
  special_chars = %w(- _).join("").codepoints

  valid_ascii_code = letters + digits + special_chars

  valid_ascii_code.include?(id) ? id.chr : ""
end
