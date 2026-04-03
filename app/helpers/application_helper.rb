# frozen_string_literal: true

module ApplicationHelper
  def force_profile_sync_on_omniauth_connection?
    current_organization.enabled_omniauth_providers.any? &&
      session["omniauth.provider"].present? &&
      Rails.application.secrets.dig(:decidim, :omniauth, :force_profile_sync)
  end

  def disable_profile_field?(field_name)
    force_profile_sync_on_omniauth_connection? && disabled_profile_fields&.include?(field_name.to_s)
  end

  def disabled_profile_fields(format = nil)
    fields = Rails.application.secrets.dig(:decidim, :omniauth, :force_profile_sync_fields) || []
    translated_field_names = fields.map { |field| t("activemodel.attributes.user.#{field}") }
    case format
    when :comma_separated_string
      translated_field_names.join(", ")
    when :html_list
      content_tag(:ul) do
        translated_field_names.each do |field|
          concat(content_tag(:li, field))
        end
      end
    else
      fields
    end
  end
end
