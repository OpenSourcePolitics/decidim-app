# frozen_string_literal: true

module Decidim
  class DrupalMeetingsImporterService
    ERRORS = OpenStruct.new(
      INVALID_ROWS: "No data found for node"
    )
    def self.run(**args)
      new(**args).execute
    end

    def initialize(**args)
      @logger = LoggerWithStdout.new("log/import-bdx-meetings--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
      @logger.warn "Rake(import:bdx:meetings)> initializing..."
      @organization = args[:organization]
      @path = args[:path]
      @locale = @organization.default_locale
      @errors = []
      @errors_comments = []
      @author = @organization
    end

    # rubcop:disable Metrics/CyclomaticComplexity
    # rubcop:disable Metrics/PerceivedComplexity
    # rubcop:disable Metrics/CyclomaticComplexity
    #
    def execute
      @logger.warn "Rake(import:bdx:meetings)> executing..."

      rows = CSV.read(@path, headers: true)

      if rows.blank?
        @logger.warn "Rake(import:bdx:meetings)> No rows found in CSV file at path #{@path}"
        return
      end

      @logger.warn "Rake(import:bdx:meetings)> found #{rows.size} rows to process"

      rows.each do |raw_data|
        row = raw_data.to_h

        unless row_valid?(row)
          @logger.warn { "Rake(import:bdx:meetings)> CSV row for #{row["url"]} is missing import data" }
          @errors.push(row.merge({ error: ERRORS.INVALID_ROWS, type: ERRORS.INVALID_ROWS.class }))
          next
        end

        meeting_component = get_attr_for(row)

        drupal_page = Decidim::DrupalPage.scrape(url: row["url"])
        raise if drupal_page.errors.present?

        drupal_page.calendars.each do |url|
          meeting_page = Decidim::Drupal::MeetingPageService.scrape(url: url)

          next if meeting_page.blank?
          next if meeting_page.errors.present?

          meeting = Decidim::Meetings::Meeting.new(
            title: { "fr" => meeting_page.title },
            description: { "fr" => meeting_page.description },
            start_time: advance_time(meeting_page.date, 12),
            end_time: advance_time(meeting_page.date, 14),
            component: meeting_component,
            published_at: advance_time(meeting_page.date, 10),
            location: { "fr" => meeting_page.location },
            address: meeting_page.address,
            author: @author,
            closed_at: advance_time(meeting_page.date, 14)
          )
          meeting.save!
        end
      rescue StandardError => e
        @logger.warn { "Rake(import:bdx:meetings)>  #{e.class}: '#{e.message}'" }
        @errors.push(row.merge({ error: "#{e.class}: #{e.message}", location: e.backtrace[0] }))
        next
      end

      @logger.warn "#{@created} contributions created"
      @logger.warn "#{@processed} processes imported"
      @logger.warn "#{@errors.size + @errors_comments.size} errors"
      write_csv_error_file if @errors.present?
      write_csv_error_comment_file if @errors_comments.present?
      @logger.warn "Rake(import:bdx:meetings)> terminated"
    end
    # rubcop:disable Metrics/CyclomaticComplexity
    # rubcop:disable Metrics/PerceivedComplexity
    # rubcop:disable Metrics/CyclomaticComplexity

    private

    def advance_time(date, hours_int)
      Date.parse(date) + hours_int.hours
    rescue StandardError => e
      @logger.warn { "Rake(import:bdx:meetings)>  #{e.class}: '#{e.message}'" }
      Time.zone.today
    end

    def get_attr_for(row)
      root_node_id = row["drupal_node_id"]
      meeting_component = Decidim::Component.find_by!(manifest_name: "meetings", id: row["decidim_meeting_id"])
      participatory_space = Decidim::ParticipatoryProcess.find(row["decidim_participatory_process_id"])

      @logger.warn "Rake(import:bdx:meetings)> No component found for node #{root_node_id}" if meeting_component.blank?

      @logger.warn "Rake(import:bdx:meetings)> No participatory space found for node #{root_node_id}" if participatory_space.blank?

      meeting_component
    end

    def row_valid?(row)
      return if row["decidim_participatory_process_id"].blank?
      return if row["decidim_meeting_id"].blank?
      return if row["url"].blank?

      true
    end

    def write_csv_error_file
      Dir.mkdir("tmp/drupal_import") unless File.exist?("tmp/drupal_import")
      file_path = "tmp/drupal_import/errors--import-bdx-meetings--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv"
      FileUtils.mkdir_p(File.dirname(file_path))
      file_exists = File.exist?(file_path) && !File.zero?(file_path)

      @logger.warn "Rake(import:bdx:meetings)> Writing errors..."
      CSV.open(file_path, "a") do |csv|
        csv << @errors.first.keys unless file_exists || @errors.empty?
        @errors.each do |error|
          @logger.warn "Rake(import:bdx:meetings:error)> #{error.values}"
          csv << error.values
        end
      end
    end
  end
end
