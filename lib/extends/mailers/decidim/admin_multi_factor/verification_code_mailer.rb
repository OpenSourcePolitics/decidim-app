# frozen_string_literal: true

require "active_support/concern"
module VerificationCodeMailerExtends
  extend ActiveSupport::Concern

  included do
    helper_method :confirm_path_url

    private

    def confirm_path_url
      "#{root_url}#{decidim_friendly_signup.confirmation_codes_path(confirmation_token: @token)}"
    end

    def root_url
      @root_url ||= decidim.root_url(host: @organization.host)[0..-2]
    end
  end
end

Decidim::AdminMultiFactor::VerificationCodeMailer.include(VerificationCodeMailerExtends)
