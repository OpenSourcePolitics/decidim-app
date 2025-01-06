# frozen_string_literal: true

class ClearDuplicatedHalfSignupUsersJob < ApplicationJob
  include Decidim::Logging

  def perform
    Benchmark.bm do |x|
      x.report do

        if duplicated_phone_numbers.blank?
          log! "No duplicated phone numbers found"
          return
        end

        alerts = duplicated_phone_numbers.map do |phone_info|
          phone_number, phone_country = phone_info
          users_with_phone = Decidim::User.where(phone_number: phone_number, phone_country: phone_country)
          decidim_user_dup_accounts = []

          users_with_phone.each do |user|
            if user.email.include?("quick_auth")
              soft_delete_user(user, "HalfSignup duplicated account")
            else
              decidim_user_dup_accounts << user
            end
          end

          generate_alert_message(phone_number, decidim_user_dup_accounts) if decidim_user_dup_accounts.map(&:email).uniq.size > 1
        end.compact!

        display_alerts(alerts)
      end
    end
  end

  private

  def duplicated_phone_numbers
    @duplicated_phone_numbers ||= Decidim::User
                                    .where.not(phone_number: [nil, ""])
                                    .where.not(phone_country: [nil, ""])
                                    .group(:phone_number, :phone_country)
                                    .having("count(*) > 1")
                                    .pluck(:phone_number, :phone_country)
  end

  def soft_delete_user(user, reason)
    unless user.email.include?("quick_auth")
      log! "User (##{user.id}) - Decidim user, skipping deletion..."
      return
    end

    email = user.email
    phone = user.phone_number
    user.extended_data = user.extended_data.merge({
                                                    half_signup: {
                                                      email: email,
                                                      phone_number: phone,
                                                      phone_country: user.phone_country,
                                                    }
                                                  })

    user.phone_number = nil
    user.phone_country = nil
    form = Decidim::DeleteAccountForm.from_params(delete_reason: reason)
    Decidim::DestroyAccount.call(user, form) do
      on(:ok) do
        log!("User (ID/#{user.id} email/#{email} phone/#{obfuscate_phone_number(phone)}) has been deleted")
      end
      on(:invalid) do
        log!("User (ID/#{user.id} email/#{email} phone/#{obfuscate_phone_number(phone)}) cannot be deleted: #{form.errors.full_messages}")
      end
    end
  end

  def generate_alert_message(phone_number, users)
    phone = obfuscate_phone_number(phone_number)
    infos = users.map { |user| "(ID/#{user.id} email/#{user.email})" }

    <<~MSG
      #{phone} : #{infos.join(" | ")}
    MSG
  end

  def display_alerts(alerts)
    return if alerts.empty?

    log!("Users to cleanup manually :")
    alerts.each do |alert|
      log!(alert)
    end
  end

  def obfuscate_phone_number(phone_number)
    return "No phone number" if phone_number.blank?

    visible_prefix = phone_number[0..1]
    visible_suffix = phone_number[-2..]
    obfuscated_middle = "*" * (phone_number.length - 4)

    visible_prefix + obfuscated_middle + visible_suffix
  end
end
