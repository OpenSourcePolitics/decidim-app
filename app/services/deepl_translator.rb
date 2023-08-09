# frozen_string_literal: true

class DeeplTranslator
  attr_reader :text, :source_locale, :target_locale, :resource, :field_name

  def initialize(resource, field_name, text, target_locale, source_locale)
    @resource = resource
    @field_name = field_name
    @text = text
    @target_locale = target_locale
    @source_locale = source_locale
  end

  def translate
    if translatable_locale?(target_locale)
      translation = DeepL.translate text, source_locale, target_locale

      Decidim::MachineTranslationSaveJob.perform_later(
        resource,
        field_name,
        target_locale,
        translation.text
      )
    else
      Rails.logger.info "DeepL: #{target_locale} is not a translatable locale"
    end
  end

  def translatable_locale?(locale)
    deepl_translatable_locales.include?(locale)
  end

  def deepl_translatable_locales
    Rails.cache.fetch("deepl_translatable_locales", expires_in: 1.day) do
      DeepL.languages.map(&:code).map(&:downcase)
    end
  end
end
