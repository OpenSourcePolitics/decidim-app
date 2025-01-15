# frozen_string_literal: true

class ClearDuplicatedHalfSignupUsersJob < ApplicationJob
  include Decidim::Logging

  def perform
    @dup_decidim_users_count = 0
    @dup_half_signup_count = 0

    log! "Start clearing half signup accounts..."
    if duplicated_phone_numbers.blank?
      log! "No duplicated phone numbers found"
      return
    end

    log! "Found #{duplicated_phone_numbers.count} duplicated phone number to cleanup"
    duplicated_phone_numbers.each do |phone_info|
      phone_number, phone_country = phone_info
      users = Decidim::User.where(phone_number: phone_number, phone_country: phone_country)

      clear_data users
    end

    log! "Total distinct numbers to clear : #{duplicated_phone_numbers.size}"
    log! "Half signup users archived : #{@dup_half_signup_count}"
    log! "Decidim users account updated : #{@dup_decidim_users_count}"
    log! "Total accounts modified : #{@dup_half_signup_count + @dup_decidim_users_count}"
    log! "Terminated !"
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

  def clear_data(users)
    decidim_user_dup_accounts = []

    users.each do |user|
      if user.email.include?("quick_auth")
        @dup_half_signup_count += 1
        soft_delete_user(user, delete_reason)
      else
        @dup_decidim_users_count += 1
        decidim_user_dup_accounts << user
      end
    end

    return if decidim_user_dup_accounts.blank?
    # The unique user might be a user without email, if so, it should be cleared
    return if decidim_user_dup_accounts.size <= 1 && decidim_user_dup_accounts.first.email.present?

    # if there is multiple decidim user accounts, clear all phone number for these accounts
    decidim_user_dup_accounts.each do |decidim_user|
      clear_account_phone_number(decidim_user)
    end
  end

  def soft_delete_user(user, reason)
    return unless user.email&.include?("quick_auth")

    email = user.email
    phone = user.phone_number
    user.extended_data = user.extended_data.merge({
                                                    half_signup: {
                                                      email: email,
                                                      phone_number: phone,
                                                      phone_country: user.phone_country
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

  def clear_account_phone_number(user)
    phone_number = user.phone_number
    Decidim::User.transaction do
      user.extended_data = user.extended_data.merge({
                                                      half_signup: {
                                                        phone_number: user.phone_number,
                                                        phone_country: user.phone_country
                                                      }
                                                    })

      user.phone_number = nil
      user.phone_country = nil
      user.save(validate: false)
    end

    log! "User (ID/#{user.id} phone/#{obfuscate_phone_number(phone_number)} email/#{user.email}) has been cleaned"
  end

  def obfuscate_phone_number(phone_number)
    return "No phone number" if phone_number.blank?

    visible_prefix = phone_number[0..1]
    visible_suffix = phone_number[-2..]
    obfuscated_middle = "*" * (phone_number.length - 4)

    visible_prefix + obfuscated_middle + visible_suffix
  end

  def current_date
    Date.current.strftime "%Y-%m-%d"
  end

  def delete_reason
    "HalfSignup duplicated account (#{current_date})"
  end
end
