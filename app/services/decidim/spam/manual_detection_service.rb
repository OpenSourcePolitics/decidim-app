# frozen_string_literal: true

module Decidim
  module Spam
    class ManualDetectionService
      DEFAULT_OPTIONS = {
        batch_size: 1000,
        batch_order: :asc,
        session_id: Time.zone.now.strftime("%Y%m%d%H%M%S"),
        sign_in_count_threshold: 2,
        save_users: false,
        block_users: false,
        block_suspicious_users: false,
        dirty_block: false,
        export_analyzed_users: false,
        ignore_previous_analysis: false,
        whatlanguage: {
          only: [:french],
          min_chars: 0
        }
      }.freeze

      SPAM_RESULTS_KEYS_ORDER = [
        :personal_url,
        :about,
        :avatar_attached,
        :optional_profile_info_count,
        :low_sign_in_count,
        :suspicious_language,
        :score,
        :conclusion
      ].freeze

      ANALYSIS_REPORT_SPAM_KEYS_ORDER = [
        :analyzable,
        :personal_url,
        :about,
        :avatar_attached,
        *(0..3).map { |i| "optional_profile_info_count#{i}".to_sym },
        :low_sign_in_count,
        :suspicious_language,
        :score,
        *(%w(unknown suspicious spam not_spam).map { |status| "conclusion_#{status}".to_sym })
      ].freeze

      attr_reader :organization, :options, :whatlanguage, :analysis_results

      def initialize(organization:, **options)
        @organization = organization
        raise ArgumentError, "Invalid organization provided : #{organization.inspect}" if @organization.nil? || !@organization.is_a?(Decidim::Organization)

        @options = DEFAULT_OPTIONS.deep_merge(options)
        # @whatlanguage = WhatLanguage.new(**@options[:whatlanguage]) if @options[:whatlanguage].present?
        @whatlanguage = WhatLanguage.new

        @analysis_report = preflight_report
        # TODO(review): this loads every analyzable user into memory at once, unbatched.
        # Could be an issue on a large organization. Maybe it's worth batching with
        # find_each/find_in_batches before running on a big instance.
        @analysis_results = analyzable_users.to_a
      end

      def preflight_report
        {
          **options,
          organization: {
            id: organization.id,
            name: organization.name,
            host: organization.host
          },
          users: {
            total: organization.user_entities.count,
            groups: organization.user_entities.select { |u| u.type == "Decidim::UserGroup" }.count,
            admins: organization.admins.count,
            available: organization.users.available.count,
            confirmed: organization.users.confirmed.count,
            blocked: organization.users.blocked.count,
            deleted: organization.users.where.not(deleted_at: nil).count,
            legacy_spam_users: organization.users.where("extended_data -> 'spam_detection' ? :key", key: "reported_at").count,
            already_analyzed_users: organization.users.where("extended_data -> 'spam_detection' ? :key", key: "manual").count
          },
          spam: {
            analyzable: analyzable_users.count
          }
        }
      end

      def analysis_report
        @analysis_report.merge(
          spam: @analysis_report[:spam].reverse_merge(
            ANALYSIS_REPORT_SPAM_KEYS_ORDER.index_with { nil }
          ).compact
        )
      end

      # TODO : check users blocked for other reasons than spam detection
      def analyzable_users
        @analyzable_users ||= begin
          Rails.logger.debug "Performing analyzable_users query"
          base_query = organization.users.available
          base_query = base_query.where.not(quick_auth_users_sql)
          base_query = base_query.where.not(legacy_spam_unreported_users_sql)
          base_query = base_query.where.not(already_analyzed_users_sql) unless options[:ignore_previous_analysis]

          begin
            base_query = base_query.where("created_at < ?", Date.parse(options[:before]).to_fs(:db)) if options[:before].present?
          rescue Date::Error
            Rails.logger.error "Invalid date format for options[:before]: #{options[:before]}"
          end

          begin
            base_query = base_query.where("created_at > ?", Date.parse(options[:after]).to_fs(:db)) if options[:after].present?
          rescue Date::Error
            Rails.logger.error "Invalid date format for options[:after]: #{options[:after]}"
          end

          base_query = base_query.limit(options[:limit]) if options[:limit].present?
          base_query = base_query.order(options[:order]) if options[:order].present?
          # TODO(review): this join's result isn't reassigned to base_query, so it has no
          # effect, avatar.attached? in analyse_user falls back to one query per user
          # (N+1, visible in the logs as individual ActiveStorage::Attachment Load calls).
          # Should be `base_query = base_query.joins(:avatar_attachment)` (or dropped if
          # unused), can you confirm which was intended?
          base_query.joins(:avatar_attachment)
          base_query
        end
        # .tap(&:load)# Ensure the query is executed and cached
      end

      def quick_auth_users_sql
        "email LIKE 'quick_auth-%@#{organization.host}'"
      end

      def legacy_spam_unreported_users_sql
        "(extended_data ? 'spam_detection') AND (extended_data -> 'spam_detection' ? 'unreported_at')"
      end

      def already_analyzed_users_sql
        "(extended_data ? 'spam_detection') AND (extended_data -> 'spam_detection' ? 'manual')"
      end

      def analyse_user(user)
        {
          score: 0,
          conclusion: "unknown"
        }.tap do |results|
          process_simple_analysis_rule(results, :personal_url, user.personal_url.present?)
          process_simple_analysis_rule(results, :about, user.about.present?)
          process_simple_analysis_rule(results, :avatar_attached, user.avatar.attached?)

          optional_profile_info_count = 0
          optional_profile_info_count += 1 if user.personal_url.present?
          optional_profile_info_count += 1 if user.about.present?
          optional_profile_info_count += 1 if user.avatar.attached?
          results[:optional_profile_info_count] = optional_profile_info_count
          update_report_counter("optional_profile_info_count#{optional_profile_info_count}".to_sym, true)

          process_simple_analysis_rule(results, :low_sign_in_count, user.sign_in_count < options[:sign_in_count_threshold])
          process_simple_analysis_rule(results, :suspicious_language, whatlanguage.present? && user.about.present? && whatlanguage.language(user.about) != :french)

          user_analysis_conclusion(results)
        end.reverse_merge(
          SPAM_RESULTS_KEYS_ORDER.index_with { nil }
        ).compact.with_indifferent_access
      end

      def process_simple_analysis_rule(results, key, boolean_value)
        results[key.to_sym] = boolean_value
        results[:score] += 1 if boolean_value
        update_report_counter(key, boolean_value)
      end

      def update_report_counter(key, boolean_value)
        @analysis_report[:spam][key.to_sym] ||= 0
        @analysis_report[:spam][key.to_sym] += 1 if boolean_value
      end

      # rubocop:disable Style/ConditionalAssignment
      def user_analysis_conclusion(results)
        if results[:score] >= 5
          results[:conclusion] = "spam"
        elsif results[:score] == 4
          if results[:suspicious_language] || results[:low_sign_in_count]
            results[:conclusion] = "spam"
          else
            results[:conclusion] = "suspicious"
          end
        elsif results[:suspicious_language]
          results[:conclusion] = "suspicious"
          # elsif results[:score] == 0
          #   results[:conclusion] = "not_spam"
        end
        update_report_counter("conclusion_#{results[:conclusion]}".to_sym, true)
      end
      # rubocop:enable Style/ConditionalAssignment

      def run
        run_started_at = Time.current
        @analysis_results = []
        user_processed = 0
        analyzable_users.find_each(batch_size: options[:batch_size], order: options[:batch_order]) do |user|
          Rails.logger.info "Analyzing user (#{user.class}) #{user.id} (#{user.email})"
          user.extended_data["spam_detection"] ||= {}
          user.extended_data["spam_detection"]["manual"] = {
            session_id: options[:session_id]
          }.merge(analyse_user(user))

          # user.save!(validate: false) if options[:save_users]
          user.update_columns(extended_data: user.extended_data) if options[:save_users] # rubocop:disable Rails/SkipsModelValidations

          @analysis_results << user

          user_processed += 1
        end
        run_finished_at = Time.current
        @analysis_report[:run] = {
          started_at: run_started_at,
          finished_at: run_finished_at,
          processed: user_processed,
          duration: ActiveSupport::Duration.build(run_finished_at - run_started_at).inspect
        }
      end

      def export_results
        export_path = Rails.root.join("tmp/spam/manual-spam-detection", "#{options[:session_id]}--#{organization.host}")
        FileUtils.mkdir_p(export_path) unless File.directory?(export_path)

        export_path.join("analysis_report.json").tap do |path|
          path.write(JSON.pretty_generate(@analysis_report))
        end

        return unless @analysis_results.present? && options[:export_analyzed_users]

        export_path.join("analysis_results.csv").tap do |path|
          path.write(Decidim::Exporters::CSV.new(@analysis_results, Decidim::Spam::ManualUserReportSerializer).export.read)
        end
      end
    end
  end
end
