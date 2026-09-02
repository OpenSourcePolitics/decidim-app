# frozen_string_literal: true

module OmniauthHelperExtends
  FRANCE_CONNECT_DEFAULT_ICONS = {
    icon_path: "media/images/franceconnect-btn-principal.svg",
    icon_hover_path: "media/images/franceconnect-btn-principal-hover.svg"
  }.freeze

  FALLBACK_ICON_NAME = "login-box-line"

  def full_image_button?(provider)
    icons = provider_icon_settings(provider)
    icons[:icon_path].present? && icons[:icon_hover_path].present?
  end

  def oauth_icon_with_hover(provider)
    icons = provider_icon_settings(provider)
    return oauth_icon(provider) unless icons[:icon_path].present? && icons[:icon_hover_path].present?

    icon_html = external_icon(icons[:icon_path], class: "block group-hover/oauth-icon:hidden")
    icon_html += external_icon(icons[:icon_hover_path], class: "hidden group-hover/oauth-icon:block")
    icon_html.html_safe
  end

  def oauth_icon(provider)
    icons = provider_icon_settings(provider)
    return external_icon(icons[:icon_path]) if icons[:icon_path].present?

    icon(safe_icon_name(provider, icons[:icon]))
  end

  def omniauth_provider_label(provider)
    custom_provider_display_name(provider) ||
      current_organization.enabled_omniauth_providers.dig(provider.to_sym, :display_name).presence ||
      humanized_provider_name(provider)
  end

  def normalize_provider_name(provider)
    return "x" if provider == :twitter

    provider.to_s.split("_").first
  end

  private

  def custom_provider_display_name(provider)
    scoped_key = "decidim.devise.shared.links.provider_display_name_#{provider}"
    return I18n.t(scoped_key, provider: humanized_provider_name(provider)) if term_customizer_override?(scoped_key)

    shared_key = "decidim.devise.shared.links.provider_display_name"
    return I18n.t(shared_key, provider: humanized_provider_name(provider)) if term_customizer_override?(shared_key)

    nil
  end

  def term_customizer_override?(key)
    defined?(Decidim::TermCustomizer::Translation) &&
      Decidim::TermCustomizer::Translation.exists?(key:)
  end

  def humanized_provider_name(provider)
    return "X" if provider.to_sym == :twitter
    return "Google" if provider.to_sym == :google_oauth2

    provider.to_s.tr("_", " ").titleize
  end

  def provider_icon_settings(provider)
    db_info = current_organization.enabled_omniauth_providers[provider.to_sym] || {}
    global_info = global_omniauth_provider_config(provider)

    settings = {
      icon_path: db_info[:icon_path].presence || global_info[:icon_path].presence,
      icon_hover_path: db_info[:icon_hover_path].presence || global_info[:icon_hover_path].presence,
      icon: db_info[:icon].presence || global_info[:icon].presence
    }

    settings.merge!(FRANCE_CONNECT_DEFAULT_ICONS) if provider.to_sym == :france_connect && settings[:icon_path].blank?
    settings
  end

  def global_omniauth_provider_config(provider)
    return {} unless Decidim.respond_to?(:omniauth_providers)

    Decidim.omniauth_providers[provider.to_sym] || {}
  rescue StandardError
    {}
  end

  def safe_icon_name(provider, configured_icon)
    candidates = [configured_icon, "#{normalize_provider_name(provider)}-fill", FALLBACK_ICON_NAME].compact
    candidates.find { |name| icon_registered?(name) } || FALLBACK_ICON_NAME
  end

  def icon_registered?(name)
    Decidim.icons.all.has_key?(name.to_s)
  rescue StandardError
    false
  end
end

Decidim::OmniauthHelper.module_eval do
  prepend(OmniauthHelperExtends)
end
