# frozen_string_literal: true

SEARCHABLE_MODELS_CONFIG = {
  "Decidim::Proposals::Proposal" => {
    fields: {
      scope_id: :decidim_scope_id,
      participatory_space: { component: :participatory_space },
      A: :title,
      B: :searchable_author_names,
      D: :body,
      datetime: :published_at
    },
    conditions: {
      index_on_create: ->(r) { r.visible? && r.component&.published? },
      index_on_update: ->(r) { r.visible? && r.component&.published? }
    }
  },
  "Decidim::Meetings::Meeting" => {
    fields: {
      scope_id: :decidim_scope_id,
      participatory_space: { component: :participatory_space },
      A: :title,
      B: :searchable_author_names,
      D: [:description, :address],
      datetime: :start_time
    },
    conditions: {
      index_on_create: ->(r) { r.visible? && r.published? },
      index_on_update: ->(r) { r.visible? && r.published? }
    }
  },
  "Decidim::Debates::Debate" => {
    fields: {
      participatory_space: { component: :participatory_space },
      A: :title,
      B: :searchable_author_names,
      D: :description,
      datetime: :start_time
    },
    conditions: {
      index_on_create: ->(r) { r.visible? },
      index_on_update: ->(r) { r.visible? }
    }
  },
  "Decidim::Blogs::Post" => {
    fields: {
      participatory_space: { component: :participatory_space },
      A: :title,
      B: :searchable_author_names,
      D: :body,
      datetime: :created_at
    },
    conditions: {
      index_on_create: ->(r) { r.visible? },
      index_on_update: ->(r) { r.visible? }
    }
  }
}.freeze

SEARCHABLE_MODELS_CONFIG.each do |klass_name, config|
  klass_name.constantize.class_eval do
    def searchable_author_names
      if respond_to?(:authors)
        authors.map { |a| a.respond_to?(:name) ? a.name : a.title }.join(" ")
      elsif respond_to?(:author_name)
        author_name.to_s
      elsif respond_to?(:author) && author.present?
        author.respond_to?(:name) ? author.name : author.to_s
      else
        ""
      end
    rescue StandardError
      ""
    end

    searchable_fields(config[:fields], config[:conditions])
  end
rescue NameError => e
  Rails.logger.warn("[searchable_author_extends] Skipping #{klass_name}: #{e.message}")
end
