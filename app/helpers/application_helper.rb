# frozen_string_literal: true

module ApplicationHelper
  # Public: normalize entire providers names to they can be used for buttons
  # and icons.
  def normalize_full_provider_name(provider)
    provider.to_s
  end

  # Public: renders SSO link as image
  def sso_provider_image(provider, decidim, image_path = "media/images/FCboutons-10@2x.png")
    link_to decidim.send("user_#{provider}_omniauth_authorize_path"), class: "button--#{normalize_full_provider_name(provider)}", method: :post do
      image_pack_tag image_path,
                     alt: t("devise.shared.links.sign_in_with_provider",
                            provider: normalize_full_provider_name(provider).titleize)
    end
  end

  # Public: renders SSO link as HTML button
  def sso_provider_button(provider, decidim)
    link_to decidim.send("user_#{provider}_omniauth_authorize_path"), class: "button button--social button--#{normalize_provider_name(provider)}", method: :post do
      html_element = content_tag(:span, oauth_icon(provider), class: "button--social__icon")
      html_element += content_tag(:span, normalize_provider_name(provider).titleize, class: "button--social__text")

      html_element
    end
  end
end
