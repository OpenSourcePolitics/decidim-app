# frozen_string_literal: true

require "logger_with_stdout"

module Decidim
  class DrupalPpsCheckService

    def self.run(**args)
      new(**args).execute
    end

    def initialize(**args)
      @logger = ::LoggerWithStdout.new("log/import-bdx-ppscheck--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
      @logger.warn "Rake(import:bdx:ppscheck)> initializing..."
      @organization = args[:organization]
      @path = args[:path]
      @locale = @organization.default_locale
      @plist_headers = []
      @plist = []
      @errors = []
      @existing = 0
      @fixed = 0
      @missing = 0
      @processed = 0
      @dev = true
    end

    def execute
      @logger.warn "Rake(import:bdx:ppscheck)> executing..."

      rows = CSV.read(@path, headers: true)
      @plist_headers = @plist_headers.concat(rows.headers)
      @plist_headers = @plist_headers.concat(%w(
        meetings_count
        pages_count
        proposals_count
        comments_count
      ))


      if rows.blank?
        @logger.warn "Rake(import:bdx:ppscheck)> No rows found in CSV file at path #{@path}"
        return
      else
        @logger.warn "Rake(import:bdx:ppscheck)> found #{rows.size} rows to process"
      end

      rows.each do |raw_data|
        row = raw_data.to_h

        if row["decidim_participatory_process_id"].present? && Decidim::ParticipatoryProcess.exists?(row["decidim_participatory_process_id"])
          process = Decidim::ParticipatoryProcess.find(row["decidim_participatory_process_id"])
        else

          if row["decidim_participatory_process_id"].blank?
            @logger.warn { "Rake(import:bdx:ppscheck)> CSV row for #{row["url"]} is missing decidim_participatory_process_id" }
          elsif !Decidim::ParticipatoryProcess.exists?(row["decidim_participatory_process_id"])
            @logger.warn { "Rake(import:bdx:ppscheck)> Process with decidim_participatory_process_id #{row["decidim_participatory_process_id"]} not found trying with slug #{build_decidim_process_slug(row["drupal_node_id"])}" }
          end

          if row.key?("drupal_node_id")
            slug = build_decidim_process_slug(row["drupal_node_id"])
            process = Decidim::ParticipatoryProcess.find_by(slug: slug)
            if process.nil?
              @logger.warn { "Rake(import:bdx:ppscheck)> Process not found #{build_decidim_process_url(slug)}" }
              @errors.push(row.merge({ error: "Process not found #{build_decidim_process_url(slug)}" }))
              @missing += 1
              next
            end
            row["decidim_participatory_process_id"] = process.id
            row["participatory_process_url"] = build_decidim_process_url(slug)
          else
            @logger.warn { "Rake(import:bdx:ppscheck)> Missing Node ID for process #{row["url"]}" }
            @errors.push(row.merge({ error: "Missing Node ID for process #{row["url"]}" }))
            @missing += 1
            next
          end
        end

        if row_valid?(row)
          @existing += 1
        else
          @fixed += 1
        end

        meetings_component = Decidim::Component.find_by(manifest_name: "meetings", participatory_space: process)
        row["decidim_meeting_id"] = meetings_component.id unless row["decidim_meeting_id"].present?
        row["meetings_count"] = Decidim::Meetings::Meeting.where(component: meetings_component).count
 
        pages_component = Decidim::Component.find_by(manifest_name: "pages", participatory_space: process)
        row["decidim_page_id"] = pages_component.id unless row["decidim_page_id"].present?
        row["pages_count"] = Decidim::Pages::Page.where(component: pages_component).count

        proposals_component = Decidim::Component.find_by(manifest_name: "proposals", participatory_space: process)
        row["decidim_proposal_id"] = proposals_component.id unless row["decidim_proposal_id"].present?
        proposals = Decidim::Proposals::Proposal.where(component: proposals_component)
        row["proposals_count"] = proposals.count
        row["comments_count"] = Decidim::Comments::Comment.where(commentable: proposals, root_commentable: proposals).count

      rescue ActiveRecord::RecordNotFound => e
        @logger.warn { "Rake(import:bdx:ppscheck)>  #{e.class}: '#{e.message}'" }
        @errors.push(row.merge({ error: "#{e.class}: #{e.message}" }))
        @missing += 1
        next
      rescue StandardError => e
        @logger.warn { "Rake(import:bdx:ppscheck)>  #{e.class}: '#{e.message}'" }
        @errors.push(row.merge({ error: "#{e.class}: #{e.message}" }))
        next
      ensure
        @plist.push(row)
        @processed += 1
      end

      @logger.warn "#{@created} contributions created"
      # @logger.warn "#{@existing} data already existing (updated)"
      @logger.warn "#{@processed} processes"
      @logger.warn "#{@fixed} processes found and fixed with missing data"
      @logger.warn "#{@existing} processes already ok"
      @logger.warn "#{@missing} processes missing"
      @logger.warn "#{@errors.size} errors"
      write_csv_results if @plist.present?
      write_csv_error_file if @errors.present?
      @logger.warn "Rake(import:bdx:ppscheck)> terminated"
    end

    private

    def row_valid?(row)
      %w(
        decidim_participatory_process_id
        decidim_meeting_id
        decidim_page_id
        decidim_proposal_id
      ).all? { |k| row["k"].present? }
    end

    def build_decidim_process_slug(node_id)
      "projet-#{node_id}"
    end

    def build_decidim_process_url(slug)
      "https://#{@organization.host}/processes/#{slug}"
    end

    def write_csv_error_file
      Dir.mkdir("tmp/drupal_import") unless File.exist?("tmp/drupal_import")
      file_path = "tmp/drupal_import/errors--import-bdx-ppscheck--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv"
      FileUtils.mkdir_p(File.dirname(file_path))
      file_exists = File.exist?(file_path) && !File.zero?(file_path)

      CSV.open(file_path, "a") do |csv|
        csv << @errors.first.keys unless file_exists || @errors.empty?
        @errors.each do |error|
          csv << error.values
        end
      end
    end

    def write_csv_results
      Dir.mkdir("tmp/drupal_import") unless File.exist?("tmp/drupal_import")
      file_path = "tmp/drupal_import/resume-completed.csv"
      FileUtils.mkdir_p(File.dirname(file_path))
      file_exists = File.exist?(file_path) && !File.zero?(file_path)

      CSV.open(file_path, "a") do |csv|
        csv << @plist_headers
        @plist.each do |item|
          csv << @plist_headers.map { |h| item[h] }
        end
      end
    end
  end
end
