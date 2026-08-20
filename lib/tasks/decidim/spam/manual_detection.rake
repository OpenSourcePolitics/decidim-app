# frozen_string_literal: true

require "optparse"

# Options via OptionParser rather than the ENV convention used elsewhere
# requires a literal "--" before the flags, otherwise rake tries
# to interpret them as task names and it might fail.
# Example of how to use it: rake decidim_app:spam:manual_detection -- --organization-id=1 --dry-run
namespace :decidim_app do
  namespace :spam do
    spam_task_argv = lambda do
      idx = ARGV.index("--")
      idx ? ARGV[(idx + 1)..] : []
    end

    desc "Run manual spam detection for an organization (usage: rake decidim_app:spam:manual_detection -- [options])"
    task manual_detection: :environment do
      options = {}

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: rake decidim_app:spam:manual_detection -- [options]"

        opts.on("--organization-id ID", Integer, "Organization id (required if more than one organization exists)") { |v| options[:organization_id] = v }

        opts.on("--batch-size N", Integer, "Batch size (default: 1000)") { |v| options[:batch_size] = v }
        opts.on("--batch-order ORDER", %w(asc desc), "Batch order (asc/desc)") { |v| options[:batch_order] = v.to_sym }
        opts.on("--session-id ID", "Session identifier (default: timestamp)") { |v| options[:session_id] = v }
        opts.on("--sign-in-count-threshold N", Integer, "Sign-in count threshold (default: 2)") { |v| options[:sign_in_count_threshold] = v }

        opts.on("--save-users", "Persist analysis results on users") { options[:save_users] = true }
        opts.on("--export-analyzed-users", "Export a CSV of analyzed users") { options[:export_analyzed_users] = true }
        opts.on("--ignore-previous-analysis", "Re-analyze users that were already reviewed") { options[:ignore_previous_analysis] = true }

        opts.on("--before DATE", "Users created before this date (YYYY-MM-DD)") { |v| options[:before] = v }
        opts.on("--after DATE", "Users created after this date (YYYY-MM-DD)") { |v| options[:after] = v }
        opts.on("--limit N", Integer, "Limit the number of analyzable users") { |v| options[:limit] = v }
        opts.on("--order ORDER", "Raw SQL order applied to the query (e.g. 'created_at ASC')") { |v| options[:order] = v }

        opts.on("--dry-run", "Force save_users/export_analyzed_users to false, report only") { options[:dry_run] = true }

        opts.on("-h", "--help", "Show this help") do
          puts opts
          exit
        end
      end

      begin
        parser.parse!(spam_task_argv.call)
      rescue OptionParser::ParseError => e
        abort "Failed to parse options: #{e.message}\n\n#{parser}"
      end

      organization_id = options.delete(:organization_id)
      raise ArgumentError, "Multiple organizations found, please specify --organization-id" if Decidim::Organization.count > 1 && organization_id.blank?

      organization = Decidim::Organization.find(organization_id || 1)

      if options.delete(:dry_run)
        options[:save_users] = false
        options[:export_analyzed_users] = false
      end

      Rails.logger.warn "(decidim_app:spam:manual_detection)> Starting manual detection..."

      service = Decidim::Spam::ManualDetectionService.new(organization:, **options)
      Rails.logger.warn "(decidim_app:spam:manual_detection)> Preflight report:\n#{JSON.pretty_generate(service.preflight_report)}"

      service.run
      Rails.logger.warn "(decidim_app:spam:manual_detection)> Analysis report:\n#{JSON.pretty_generate(service.analysis_report)}"

      if options[:export_analyzed_users]
        service.export_results
        Rails.logger.warn "(decidim_app:spam:manual_detection)> Results exported to tmp/spam/manual-spam-detection/#{service.options[:session_id]}--#{organization.host}"
      end

      Rails.logger.warn "(decidim_app:spam:manual_detection)> Terminated"
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "(decidim_app:spam:manual_detection)> Organization not found: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "(decidim_app:spam:manual_detection)> An error occurred: #{e.message}"
    end
  end
end
