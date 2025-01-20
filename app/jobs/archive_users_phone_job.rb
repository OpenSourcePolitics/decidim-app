# frozen_string_literal: true

class ArchiveUsersPhoneJob < ApplicationJob
  include Decidim::Logging

  def perform
    metrics = { total: 0, quick_auth_users: 0, decidim_users: 0 }
    log! "Start clearing phone numbers from accounts..."

    users_to_archive.find_in_batches(batch_size: 1000) do |users|
      users.each do |user|
        metrics[:total] += 1

        if user.email.include?("quick_auth")
          metrics[:quick_auth_users] += 1
          soft_delete_user(user, delete_reason)
        else
          metrics[:decidim_users] += 1
          clear_account_phone_number(user)
        end
      end
    end

    log! "Total distinct numbers to clear : #{metrics[:total]}"
    log! "Half signup users archived : #{metrics[:quick_auth_users]}"
    log! "Decidim users account updated : #{metrics[:decidim_users]}"
    log! "Terminated !"
  end

  private

  def users_to_archive
    Decidim::User.where.not(phone_number: [nil, ""]).where.not(phone_country: [nil, ""])
  end

  def soft_delete_user(user, reason)
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
      on(:invalid) do
        log!("User (ID/#{user.id} email/#{email} phone/#{obfuscate_phone_number(phone)}) cannot be deleted: #{form.errors.full_messages}")
      end
    end
  end

  def clear_account_phone_number(user)
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
  end

  def current_date
    Date.current.strftime "%Y-%m-%d"
  end

  def delete_reason
    "Archived account - #{current_date}"
  end
end
