# frozen_string_literal: true

# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Security/Open
module Decidim
  class DrupalDecisionsImporterService
    RAKE_NAME = "import:bdx:decisions"

    def self.run(**args)
      new(**args).execute
    end

    def initialize(**args)
      Rails.logger.warn "Rake(#{RAKE_NAME})> initializing..."
      @path = args[:path]
      @organization = args[:organization]
      @errors = []
    end

    def execute
      Rails.logger.warn "Rake(#{RAKE_NAME})> executing..."
      rows = CSV.read(@path, headers: true)

      if rows.blank?
        Rails.logger.warn "Rake(#{RAKE_NAME})> No rows found"
        return
      end

      rows.each do |row|
        drupal_page = Decidim::DrupalPage.scrape(url: row["url"])
        if drupal_page.blank?
          @errors << "URL not found: #{row["url"]}"
        end
        pp = Decidim::ParticipatoryProcess.find_by(slug: "projet-#{drupal_page.drupal_node_id}")
        if pp.blank?
          @errors << "ParticipatoryProcess not found: #{drupal_page.drupal_node_id}"
        end

        if (error = edit_decision_page!(drupal_page, pp)).present?
          @errors << error
        end

        sleep 0.75
      end

      Rails.logger.warn "Rake(#{RAKE_NAME})> #{@errors.count} errors: #{@errors.join(" | ")}"
      Rails.logger.warn "Rake(#{RAKE_NAME})> terminated"
    end

    private

    def edit_decision_page!(drupal_page, pp)
      component = Decidim::Component.find_by(name: "BILANS & DÉCISIONS", manifest_name: "pages", participatory_space: pp)
      if component.blank?
        Rails.logger.warn "Rake(#{RAKE_NAME})> :not_found: component for '#{drupal_page.url}' not found"
        return ":not_found: component for '#{drupal_page.url}' not found"
      end

      page = Decidim::Pages::Page.find_by(component: component)
      if page.blank?
        Rails.logger.warn "Rake(#{RAKE_NAME})> :not_found: page for '#{drupal_page.url}' not found"
        return "not_found: page for '#{drupal_page.url}' not found"
      end
      page.body = { "fr" => drupal_page.get_bilan.presence || "." }
      page.save!
      return
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Security/Open
