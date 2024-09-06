# frozen_string_literal: true

require "logger_with_stdout"

module Decidim
  class DrupalProposalImporterService
    COLUMNS = %w(
      uid
      name
      mail
      status
      created
      access
      login
    ).freeze

    EMAIL_REGEX_PATTERN = /^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$/

    def self.run(**args)
      new(**args).execute
    end

    def initialize(**args)
      @logger = ::LoggerWithStdout.new("log/import-bdx-proposals--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
      @logger.warn "Rake(import:bdx:proposals)> initializing..."
      @organization = args[:organization]
      @path = args[:path]
      @locale = @organization.default_locale
      @errors = []
      @errors_comments = []
      @existing = 0
      @created = 0
      @processed = 0
      @dev = true
    end

    def execute
      @logger.warn "Rake(import:bdx:proposals)> executing..."

      rows = CSV.read(@path, headers: true)

      if rows.blank?
        @logger.warn "Rake(import:bdx:proposals)> No rows found in CSV file at path #{@path}"
        return
      else
        @logger.warn "Rake(import:bdx:proposals)> found #{rows.size} rows to process"
      end

      rows.each do |raw_data|
        row = raw_data.to_h

        if row_valid?(row)
          errors_comments_count = @errors_comments.size
          import_process_comments_to_proposals(row)
          errors_comments_count = @errors_comments.size - errors_comments_count
          if errors_comments_count.positive?
            @logger.warn { "Rake(import:bdx:proposals)> CSV row for #{row["url"]} has errors" }
            @errors.push(row.merge({ error: "#{errors_comments_count} found on this process. see 'errors--import-bdx-proposals--comments' CSV for details" }))
          end
        else
          @logger.warn { "Rake(import:bdx:proposals)> CSV row for #{row["url"]} is missing import data" }
          @errors.push(row.merge({ error: "missing import data" }))
          next
        end
      rescue StandardError => e
        @logger.warn { "Rake(import:bdx:proposals)>  #{e.class}: '#{e.message}'" }
        @errors.push(row.merge({ error: "#{e.class}: #{e.message}" }))
        next
      end

      @logger.warn "#{@created} contributions created"
      # @logger.warn "#{@existing} data already existing (updated)"
      @logger.warn "#{@processed} processes imported"
      @logger.warn "#{@errors.size + @errors_comments.size} errors"
      write_csv_error_file if @errors.present?
      write_csv_error_comment_file if @errors_comments.present?
      @logger.warn "Rake(import:bdx:proposals)> terminated"
    end

    private

    def import_process_comments_to_proposals(row)
      root_node_id = row["drupal_node_id"]
      # target_process = Decidim::ParticipatoryProcess.find(row["decidim_participatory_process_id"])
      target_component = Decidim::Component.find_by!(manifest_name: "proposals", id: row["decidim_proposal_id"])

      source_records = select_comments_from_external_db(root_node_id)

      if source_records.blank?
        @logger.warn "Rake(import:bdx:proposals)> No data found for node #{root_node_id}"
        return
      else
        @logger.warn "Rake(import:bdx:proposals)> found #{source_records.size} rows to process for node #{root_node_id}"
      end

      source_records.each do |record|
        find_or_create_default_anonymous_user if record.uid.zero?
        if record.pid.zero?
          create_proposal(target_component, record)
        else
          create_comment_on_proposal(create_import_reference(record.pid), record)
        end
      rescue StandardError => e
        @logger.warn { "Rake(import:bdx:proposals)>  #{e.class}: '#{e.message}'" }
        @errors_comments.push(record.as_json.merge({ error: "#{e.class}: #{e.message}" }))
        next
      end
      @processed += 1
    end

    def row_valid?(row)
      row["decidim_participatory_process_id"].present? && row["decidim_proposal_id"].present?
    end

    def select_comments_from_external_db(nid)
      ::Drupal::Comment.where(nid: nid, status: 1).order(pid: :ASC)
    end

    def create_proposal(component, record)
      proposal = Decidim::Proposals::Proposal.new(
        component: component,
        title: translated_attribute(@locale, record.subject),
        body: translated_attribute(@locale, record.body),
        reference: create_import_reference(record.cid),
        state: "accepted",
        created_at: integer_to_datetime(record.created),
        updated_at: integer_to_datetime(record.created),
        published_at: integer_to_datetime(record.created)
      )

      proposal.add_coauthor(record.user)
      proposal.save!(validate: false, touch: false)
      @created += 1
    end

    def create_comment_on_proposal(reference, record)
      proposal = Decidim::Proposals::Proposal.find_by!(reference: reference)
      Decidim::Comments::Comment.new(
        commentable: proposal,
        root_commentable: proposal,
        author: record.user,
        body: translated_attribute(@locale, record.body),
        created_at: integer_to_datetime(record.created),
        updated_at: integer_to_datetime(record.created)
      ).save!(validate: false, touch: false)
      @created += 1
    end

    def find_or_create_default_anonymous_user
      user ||= Decidim::User.where("extended_data::jsonb @> :drupal", drupal: { drupal: { uid: 0 } }.to_json).first
      if user.nil?
        user = Decidim::User.create!(
          name: "",
          organization: @organization,
          newsletter_notifications_at: nil,
          password: generated_password = SecureRandom.hex,
          password_confirmation: generated_password,
          deleted_at: Time.zone.now,
          tos_agreement: "1",
          extended_data: {
            drupal: {
              uid: 0
            }
          }
        )
      end
      user
    end

    def create_import_reference(pid)
      "BMDP-PROP-#{pid}"
    end

    def integer_to_datetime(value)
      Time.zone.at(value)
    end

    def translated_attribute(locale, value)
      { locale => value }
    end

    def write_csv_error_file
      Dir.mkdir("tmp/drupal_import") unless File.exist?("tmp/drupal_import")
      file_path = "tmp/drupal_import/errors--import-bdx-proposals--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv"
      FileUtils.mkdir_p(File.dirname(file_path))
      file_exists = File.exist?(file_path) && !File.zero?(file_path)

      CSV.open(file_path, "a") do |csv|
        csv << @errors.first.keys unless file_exists || @errors.empty?
        @errors.each do |error|
          csv << error.values
        end
      end
    end

    def write_csv_error_comment_file
      Dir.mkdir("tmp/drupal_import") unless File.exist?("tmp/drupal_import")
      file_path = "tmp/drupal_import/errors--import-bdx-proposals--comments--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv"
      FileUtils.mkdir_p(File.dirname(file_path))
      file_exists = File.exist?(file_path) && !File.zero?(file_path)

      CSV.open(file_path, "a") do |csv|
        csv << @errors_comments.first.keys unless file_exists || @errors_comments.empty?
        @errors_comments.each do |error|
          csv << error.values
        end
      end
    end
  end
end
