# frozen_string_literal: true

require "active_support/concern"

module OmniauthRegistrationFormExtends
  extend ActiveSupport::Concern

  included do
    attribute :certification, ::ActiveModel::Type::Boolean
    attribute :birth_date, Date
    attribute :address, String
    attribute :postal_code, String
    attribute :city, String
    attribute :tos_agreement, ::ActiveModel::Type::Boolean

    # validates :email, "valid_email_2/email": { mx: true }
    validates :postal_code,
              :birth_date,
              :city,
              :address,
              :certification,
              :tos_agreement,
              presence: true, unless: ->(form) { form.tos_agreement.blank? }

    validates :postal_code, numericality: { only_integer: true }, length: { is: 5 }, unless: ->(form) { form.tos_agreement.blank? }
    validates :certification, acceptance: true, presence: true, unless: ->(form) { form.tos_agreement.blank? }
    validates :tos_agreement, acceptance: true, presence: true
    validate :over_16?

    private

    def over_16?
      return if birth_date.blank?
      return if 16.years.ago.to_date > birth_date

      errors.add :base, I18n.t("decidim.devise.registrations.form.errors.messages.over_16")
      errors.add :birth_date, I18n.t("decidim.devise.registrations.form.errors.messages.over_16")
    end

    def normalized_nickname
      source = Rails.application.secrets.dig(:decidim, :omniauth, :ignore_nickname) ? name : (nickname || name)
      Decidim::UserBaseEntity.nicknamize(source, organization: current_organization)
    end
  end
end

Decidim::OmniauthRegistrationForm.include(OmniauthRegistrationFormExtends)
