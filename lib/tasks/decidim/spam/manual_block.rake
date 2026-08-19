# frozen_string_literal: true

require "optparse"

# Options via OptionParser rather than the ENV convention,
# requires a "--" before the flags, otherwise rake tries
# to interpret them as task names.
# Ex: rake decidim_app:spam:manual_block -- --organization-id=1 --dry-run
namespace :decidim_app do
  namespace :spam do
    block_task_argv = lambda do
      idx = ARGV.index("--")
      idx ? ARGV[(idx + 1)..] : []
    end

    desc "Run manual spam block for an organization, based on a previous manual_detection run (usage: rake decidim_app:spam:manual_block -- [options])"
    task manual_block: :environment do
      options = {}

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: rake decidim_app:spam:manual_block -- [options]"

        opts.on("--organization-id ID", Integer, "Organization id (required if more than one organization exists)") { |v| options[:organization_id] = v }

        opts.on("--batch-size N", Integer, "Batch size (default: 1000)") { |v| options[:batch_size] = v }
        opts.on("--batch-order ORDER", %w(asc desc), "Batch order (asc/desc)") { |v| options[:batch_order] = v.to_sym }
        opts.on("--session-id ID", "Session identifier (default: timestamp)") { |v| options[:session_id] = v }

        opts.on("--block-users", "Actually block the matched users") { options[:block_users] = true }
        opts.on("--block-suspicious-users", "Also block users concluded as suspicious, not just spam") { options[:block_suspicious_users] = true }
        opts.on("--dirty-block", "Block by writing columns directly, bypassing Decidim::Admin::BlockUser (no admin log entry, no notification)") { options[:dirty_block] = true }
        opts.on("--block-by-email EMAIL", "Admin user credited for the block (defaults to the organization's first admin)") { |v| options[:block_by_email] = v }

        opts.on("--before DATE", "Users created before this date (YYYY-MM-DD)") { |v| options[:before] = v }
        opts.on("--after DATE", "Users created after this date (YYYY-MM-DD)") { |v| options[:after] = v }
        opts.on("--limit N", Integer, "Limit the number of blockable users") { |v| options[:limit] = v }
        opts.on("--order ORDER", "Raw SQL order applied to the query (e.g. 'created_at ASC')") { |v| options[:order] = v }

        opts.on("--export-report", "Write block_report.json to tmp/spam/manual-spam-detection/") { options[:export_report] = true }

        opts.on("--dry-run", "Force block_users to false, report only") { options[:dry_run] = true }

        opts.on("-h", "--help", "Show this help") do
          puts opts
          exit
        end
      end

      begin
        parser.parse!(block_task_argv.call)
      rescue OptionParser::ParseError => e
        abort "Failed to parse options: #{e.message}\n\n#{parser}"
      end

      organization_id = options.delete(:organization_id)
      raise ArgumentError, "Multiple organizations found, please specify --organization-id" if Decidim::Organization.count > 1 && organization_id.blank?

      organization = Decidim::Organization.find(organization_id || 1)

      export_report = options.delete(:export_report)

      options[:block_users] = false if options.delete(:dry_run)

      Rails.logger.warn "(decidim_app:spam:manual_block)> Starting manual block..."

      service = Decidim::Spam::ManualBlockService.new(organization:, **options)
      Rails.logger.warn "(decidim_app:spam:manual_block)> Preflight report:\n#{JSON.pretty_generate(service.block_report)}"

      service.run
      Rails.logger.warn "(decidim_app:spam:manual_block)> Block report:\n#{JSON.pretty_generate(service.block_report)}"

      if export_report
        service.export_results
        Rails.logger.warn "(decidim_app:spam:manual_block)> Report exported to tmp/spam/manual-spam-detection/#{service.options[:session_id]}--#{organization.host}"
      end

      Rails.logger.warn "(decidim_app:spam:manual_block)> Terminated"
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "(decidim_app:spam:manual_block)> Organization not found: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "(decidim_app:spam:manual_block)> An error occurred: #{e.message}"
    end
  end
end
