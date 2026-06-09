# frozen_string_literal: true

require "deepl"

class DeeplTranslator
  attr_reader :resource, :field_name, :text, :target_locale, :source_locale

  def initialize(resource, field_name, text, target_locale, source_locale)
    @resource = resource
    @field_name = field_name
    @text = text
    @target_locale = target_locale
    @source_locale = source_locale
  end

  def translate
    Rails.logger.info("[DeeplTranslator] CALLED #{source_locale} -> #{target_locale}")
    Rails.logger.info("[DeeplTranslator] TEXT=#{text}")

    return if text.blank?

    api = DeepL::API.new(DeepL.configuration)
    translation = DeepL::Requests::Translate.new(api, text, source_locale.to_s, target_locale.to_s).request

    return nil if translation.nil? || translation.text.blank?

    Decidim::MachineTranslationSaveJob.perform_later(
      resource,
      field_name,
      target_locale,
      translation.text
    )
  rescue DeepL::Exceptions::QuotaExceeded => e
    Rails.logger.error("[DeeplTranslator] Quota exceeded: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("[DeeplTranslator] #{e.class} - #{e.message}")
    raise
  end
end
