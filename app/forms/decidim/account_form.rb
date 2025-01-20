# frozen_string_literal: true

module Decidim
  # The form object that handles the data behind updating a user's
  # account in their profile page.
  class AccountForm < Form
    include Decidim::HasUploadValidations

    mimic :user

    attribute :locale
    attribute :name
    attribute :nickname
    attribute :email
    attribute :password
    attribute :password_confirmation
    attribute :avatar, Decidim::Attributes::Blob
    attribute :remove_avatar, Boolean, default: false
    attribute :personal_url
    attribute :about

    validates :name, format: { with: Decidim::User::REGEXP_NAME }
    validates :email, "valid_email_2/email": { disposable: true }
    validates :nickname, format: { with: Decidim::User::REGEXP_NICKNAME }

    validates :name, presence: true, unless: :force_profile_sync_on_omniauth_connection?
    validates :email, presence: true, unless: :force_profile_sync_on_omniauth_connection?
    validates :nickname, presence: true, unless: :force_profile_sync_on_omniauth_connection?

    # bug : length helper is always displayed
    # validates :nickname, length: { maximum: Decidim::User.nickname_max_length, allow_blank: true }, unless: :force_profile_sync_on_omniauth_connection?
    validates :password, confirmation: { message: I18n.t("errors.messages.password_confirmation_message") }
    validates :password, password: { name: :name, email: :email, username: :nickname }, if: -> { password.present? }
    validates :password_confirmation, presence: true, if: :password_present
    validates :avatar, passthru: { to: Decidim::User }

    validate :unique_email, unless: :force_profile_sync_on_omniauth_connection?
    validate :unique_nickname, unless: :force_profile_sync_on_omniauth_connection?
    validate :personal_url_format

    alias organization current_organization

    def personal_url
      return if super.blank?

      return "http://#{super}" unless super.match?(%r{\A(http|https)://}i)

      super
    end

    private

    def password_present
      password.present?
    end

    def unique_email
      return true if Decidim::UserBaseEntity.where(
        organization: context.current_organization,
        email: email
      ).where.not(id: context.current_user.id).empty?

      errors.add :email, :taken
      false
    end

    def unique_nickname
      return true if nickname.blank?
      return true if Decidim::UserBaseEntity.where(
        "decidim_organization_id = ? AND LOWER(nickname) = ? ",
        context.current_organization.id,
        nickname.downcase
      ).where.not(id: context.current_user.id).empty?

      errors.add :nickname, :taken
      false
    end

    def personal_url_format
      return if personal_url.blank?

      uri = URI.parse(personal_url)
      errors.add :personal_url, :invalid if !uri.is_a?(URI::HTTP) || uri.host.nil?
    rescue URI::InvalidURIError
      errors.add :personal_url, :invalid
    end

    def force_profile_sync_on_omniauth_connection?
      !context.current_organization.sign_in_enabled? &&
        context.current_organization.enabled_omniauth_providers.any? &&
        Rails.application.secrets.dig(:decidim, :omniauth, :force_profile_sync_on_omniauth_connection)
    end
  end
end
