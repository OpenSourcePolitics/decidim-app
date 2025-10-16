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
    return if text.blank?

    translation = ::DeepL.translate text, source_locale.to_s, target_locale.to_s
    return nil if translation.nil? || translation.text.blank?

    Decidim::MachineTranslationSaveJob.perform_later(
      resource,
      field_name,
      target_locale,
      translation.text
    )
  rescue StandardError => e
    Rails.logger.error("[DeeplTranslator] #{e.class} - #{e.message}")
    nil
  end
end
