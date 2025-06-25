# frozen_string_literal: true

require "active_support/concern"

module OmniauthHelperExtends
  extend ActiveSupport::Concern

  included do
    def normalize_provider_name(provider)
      return "x" if provider == :twitter
      # customize the name of the omniauth btn login with publik
      if provider == :publik && Decidim::TermCustomizer::Translation.where(key: "decidim.devise.shared.links.log_in_with_provider").present?
        return I18n.t("decidim.devise.shared.links.log_in_with_provider")
      end

      provider.to_s.split("_").first
    end
  end
end

Decidim::OmniauthHelper.include(OmniauthHelperExtends)
