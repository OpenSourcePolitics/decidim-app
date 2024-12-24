# frozen_string_literal: true

# rubocop:disable Rails/Output
class ClearDuplicatedHalfSignupUsersJob < ApplicationJob
  include Decidim::Logging

  def perform
    duplicated_numbers = find_duplicated_phone_numbers
    return puts("No duplicated phone numbers found") if duplicated_numbers.empty?

    duplicated_numbers.each do |phone_info|
      phone_number, phone_country = phone_info

      users_with_phone = Decidim::User.where(phone_number: phone_number, phone_country: phone_country)
      quick_auth_users = users_with_phone.select { |user| user.email.include?("quick_auth") }
      other_users = users_with_phone.reject { |user| user.email.include?("quick_auth") }

      quick_auth_users.each { |user| soft_delete_user(user, "Duplicated account") }

      alert_about_duplicated_numbers(phone_number, other_users) if other_users.map(&:email).uniq.size > 1
    end
  end

  private

  def find_duplicated_phone_numbers
    Decidim::User
      .where.not(phone_number: [nil, ""])
      .where.not(phone_country: [nil, ""])
      .group(:phone_number, :phone_country)
      .having("count(*) > 1")
      .pluck(:phone_number, :phone_country)
  end

  def soft_delete_user(user, reason)
    if user.email.include?("quick_auth")
      user.update(phone_number: nil, phone_country: nil)

      form = Decidim::DeleteAccountForm.from_params(delete_reason: reason)
      previous_email = user.email
      Decidim::DestroyAccount.call(user, form) do
        on(:ok) do
          log!("User #{user.id} (#{previous_email}) has been deleted", :info)
          puts("User #{user.id} (#{previous_email}) has been deleted")
        end
        on(:invalid) do
          log!("Failed to delete user #{user.id} (#{user.email}): #{form.errors.full_messages}", :warn)
          puts("Failed to delete user #{user.id} (#{user.email}): #{form.errors.full_messages}")
        end
      end
    else
      log!("Not a Quick Auth account, skipping deletion", :info)
      puts("Not a Quick Auth account, skipping deletion")
    end
  end

  def alert_about_duplicated_numbers(phone_number, users)
    obfuscated_number = obfuscate_phone_number(phone_number)
    emails = users.map(&:email)
    email_pairs = emails.each_slice(2).map { |pair| pair.join(" | ") }

    message = <<~MSG
      \nALERT: Duplicated Phone Number Detected!

      Phone Number: #{obfuscated_number}
      Users with this number:
      #{email_pairs.join("\n")}
    MSG

    log!(message, :warn)
    puts(message)
  end

  def obfuscate_phone_number(phone_number)
    return "No phone number" if phone_number.blank?

    visible_prefix = phone_number[0..1]
    visible_suffix = phone_number[-2..]
    obfuscated_middle = "*" * (phone_number.length - 4)

    visible_prefix + obfuscated_middle + visible_suffix
  end
end
# rubocop:enable Rails/Output
