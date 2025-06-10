# frozen_string_literal: true

module OmniauthHelperExtends
  # Public: icon for omniauth buttons
  def oauth_icon_with_hover(provider)
    info = current_organization.enabled_omniauth_providers[provider.to_sym]

    icon_path = info&.dig(:icon_path)
    icon_hover_path = info&.dig(:icon_hover_path)

    return oauth_icon(provider) unless icon_path.present? && icon_hover_path.present?

    # parent html element needs to have the "group/oauth-icon" tailwind class
    icon_html = external_icon(icon_path, class: "block group-hover/oauth-icon:hidden")
    icon_html += external_icon(icon_hover_path, class: "hidden group-hover/oauth-icon:block")
    icon_html.html_safe
  end
end

Decidim::OmniauthHelper.module_eval do
  prepend(OmniauthHelperExtends)
end
