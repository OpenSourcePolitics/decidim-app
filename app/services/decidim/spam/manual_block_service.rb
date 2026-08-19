# frozen_string_literal: true

module Decidim
  module Spam
    class ManualBlockService
      DEFAULT_OPTIONS = {
        batch_size: 1000,
        batch_order: :asc,
        session_id: Time.zone.now.strftime("%Y%m%d%H%M%S"),
        block_users: false,
        block_suspicious_users: false,
        dirty_block: false
      }.freeze

      attr_reader :organization, :options, :block_report

      def initialize(organization:, **options)
        @organization = organization
        raise ArgumentError, "Invalid organization provided : #{organization.inspect}" if @organization.nil? || !@organization.is_a?(Decidim::Organization)

        @options = DEFAULT_OPTIONS.deep_merge(options)

        begin
          @current_user = organization.admins.find_by(email: @options[:block_by_email]) if @options[:block_by_email].present?
        rescue StandardError => e
          Rails.logger.error "Error finding admin user by email #{@options[:block_by_email]}: #{e.message}"
        ensure
          @current_user ||= organization.admins.first
        end

        @block_report = preflight_report
      end

      def preflight_report
        {
          **options,
          organization: {
            id: organization.id,
            name: organization.name,
            host: organization.host
          },
          spam: {
            blockable: blockable_users.count
          }
        }
      end

      def base_query_for_users
        @base_query ||= organization.users.available
      end

      # TODO(review): this doesn't exclude admins. If an admin's profile happens to match
      # the spam scoring criteria, they can end up in blockable_users like anyone else,
      # might be worth adding a `where(admin: false)` (or similar) before running this for real.
      def blockable_users
        @blockable_users ||= begin
          Rails.logger.debug "Performing blockable_users query"
          base_query = base_query_for_users

          spam_conclusions = ["spam"]
          spam_conclusions << "suspicious" if options[:block_suspicious_users]
          base_query = base_query.where(spam_conclusions_users_sql, spam_conclusions)

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
          base_query
        end
        # .tap(&:load) # Ensure the query is executed and cached
      end

      def spam_conclusions_users_sql
        "extended_data -> 'spam_detection' -> 'manual' ->> 'conclusion' = ANY (array[?])"
      end

      # TODO(review): block_user isn't rescued per-user here, so one failure (a raised
      # exception on a single user) stops the whole batch, the final report won't tell
      # you which users were actually processed before that happened. Perhaps worth wrapping the
      # block_user call so one bad user doesn't take down the rest of the run.
      def run
        run_started_at = Time.current
        user_processed = 0
        blockable_users.find_each(batch_size: options[:batch_size], order: options[:batch_order]) do |user|
          Rails.logger.debug { "Decidim::Spam::ManualBlockService.run : Processing user #{user.id} (#{user.email})" }
          block_user(user) if options[:block_users]
          user_processed += 1
        end
        run_finished_at = Time.current
        @block_report[:run] = {
          started_at: run_started_at,
          finished_at: run_finished_at,
          processed: user_processed,
          duration: ActiveSupport::Duration.build(run_finished_at - run_started_at).inspect
        }
      end

      def block_user(user)
        if options[:dirty_block]
          user.update_columns( # rubocop:disable Rails/SkipsModelValidations
            blocked: true,
            blocked_at: Time.current,
            name: "Blocked user",
            extended_data: user.extended_data.merge("user_name" => user.name),
            notifications_sending_frequency: "none"
          )
        else
          # TODO(review): the result of this call isn't checked. If the form is invalid
          # (validation failure, user already blocked, etc.), this silently will do nothing,
          # user_processed still increments in run, so the report can say "processed" for
          # users that weren't actually blocked. Worth checking the returned outcome
          # and fixing it if needed.
          Decidim::Admin::BlockUser.call(
            Decidim::Admin::BlockUserForm.new(
              user_id: user.id,
              justification: "Blocked by manual spam detection service (session #{options[:session_id]})",
              hide: true
            ).with_context(
              {
                current_user: @current_user,
                current_organization: organization
              }
            )
          )
        end
      end

      def export_results
        export_path = Rails.root.join("tmp/spam/manual-spam-detection", "#{options[:session_id]}--#{organization.host}")
        FileUtils.mkdir_p(export_path) unless File.directory?(export_path)

        export_path.join("block_report.json").tap do |path|
          path.write(JSON.pretty_generate(@block_report))
        end
      end
    end
  end
end
