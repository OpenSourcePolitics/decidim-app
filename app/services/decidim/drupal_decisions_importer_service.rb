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
      @path = args[:path]
      @organization = args[:organization]
      @errors = []
      @logger = Logger.new("log/import-decisions-#{Time.zone.now.strftime "%Y-%m-%d-%H-%M-%S"}.log")
      warn_message "initializing..."
    end

    def execute
      warn_message "executing..."
      rows = CSV.read(@path, headers: true)

      if rows.blank?
        warn_message "No rows found"
        return
      end

      warn_message "processing #{rows.size} rows..."
      rows.each do |row|
        drupal_page = Decidim::DrupalPage.scrape(url: row["url"])
        warn_message "processing #{row['url']}..."

        if drupal_page.blank?
          warn_message "URL #{row['url']} not found..."
          @errors << "URL not found: #{row["url"]}"
          next
        end

        pp = Decidim::ParticipatoryProcess.find_by(slug: "projet-#{drupal_page.drupal_node_id}")
        if pp.blank?
          @errors << "ParticipatoryProcess not found: #{row["url"]}"
          next
        end

        if (error = edit_decision_page!(drupal_page, pp)).present?
          @errors << error
        end

        sleep 0.75
      end

      warn_message "#{@errors.count} errors: #{@errors.join(" | ")}"
      warn_message "terminated"
    end

    private

    def edit_decision_page!(drupal_page, pp)

      component = Decidim::Component.find_by(name: {"fr" => "BILANS & DÉCISIONS"}, manifest_name: "pages", participatory_space: pp)
      if component.blank?
        component = Decidim::Component.find_by(name: "BILANS & DÉCISIONS", manifest_name: "pages", participatory_space: pp)
        if component.blank?
          warn_message ":not_found: component for '#{drupal_page.url}' not found"
          return ":not_found: component for '#{drupal_page.url}' not found"
        end
      end

      page = Decidim::Pages::Page.find_by(component: component)
      if page.blank?
        warn_message ":not_found: page for '#{drupal_page.url}' not found"
        return "not_found: page for '#{drupal_page.url}' not found"
      end
      page.body = { "fr" => drupal_page.get_bilan.presence || "." }
      page.save!
      return
    end

    def warn_message(msg)
      @logger.warn "Rake(#{RAKE_NAME})> #{msg}"
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Security/Open
