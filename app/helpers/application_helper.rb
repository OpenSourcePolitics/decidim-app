# frozen_string_literal: true

module ApplicationHelper
  # Public: normalize entire providers names to they can be used for buttons
  # and icons.
  def normalize_full_provider_name(provider)
    provider.to_s
  end

  # Public: renders SSO link as image
  def sso_provider_image(provider, link_to_path, image_path = "media/images/franceconnect-btn-principal@2x.png", link_class: nil)
    css_class = link_class || "button--#{normalize_full_provider_name(provider)}"

    ActionController::Base.helpers.link_to link_to_path, class: css_class, method: :post do
      image_pack_tag image_path,
                     alt: I18n.t("devise.shared.links.sign_in_with_provider",
                                 provider: normalize_full_provider_name(provider).titleize)
    end
  end

  # Public: renders SSO link as HTML button
  def sso_provider_button(provider, link_to_path)
    ActionController::Base.helpers.link_to link_to_path, class: "button button--social button--#{normalize_provider_name(provider)}", method: :post do
      html_element = content_tag(:span, oauth_icon(provider), class: "button--social__icon")
      html_element += content_tag(:span,
                                  t("sign_in_with_provider", provider: normalize_provider_name(provider).titleize,
                                                             scope: "devise.shared.links"), class: "button--social__text")

      html_element
    end
  end

  def force_profile_sync_on_omniauth_connection?
    !current_organization.sign_in_enabled? &&
      current_organization.enabled_omniauth_providers.any? &&
      Rails.application.secrets.dig(:decidim, :omniauth, :force_profile_sync_on_omniauth_connection)
  end
end
