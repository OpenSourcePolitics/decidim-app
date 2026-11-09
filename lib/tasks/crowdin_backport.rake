# frozen_string_literal: true

namespace :decidim_app do
  # Crowdin translations only land on Decidim's develop branch. This task copies
  # the ones missing from the Decidim version locked in Gemfile.lock into
  # config/locales/decidim_crowdin.<locale>.yml, which Rails loads after the
  # gems' locale files.
  #
  # Options (environment variables):
  # - CORRECTIONS=true: also apply translations the locked version already has
  #   but that differ on develop (see the report first).
  # - DECIDIM_REPO, DECIDIM_REF: read develop from an existing clone and ref
  #   instead of the shallow clone kept in tmp/decidim_crowdin.
  desc "Backport Crowdin translations from Decidim develop into the locked Decidim version"
  task :crowdin_backport, [:locale] do |_task, args|
    require Rails.root.join("lib/decidim_app/crowdin_backport").to_s

    locale = args[:locale].presence || raise(ArgumentError, "Usage: bin/rails \"decidim_app:crowdin_backport[sk]\"")
    raise ArgumentError, "Use a locale other than en" if locale == "en"

    source = if ENV["DECIDIM_REPO"].present?
               DecidimApp::CrowdinBackport::GitSource.new(path: ENV.fetch("DECIDIM_REPO"), ref: ENV.fetch("DECIDIM_REF", "origin/develop"))
             else
               DecidimApp::CrowdinBackport::GitSource.new(path: Rails.root.join("tmp/decidim_crowdin"))
             end
    output = Rails.root.join("config/locales/decidim_crowdin.#{locale}.yml")
    report = Rails.root.join("tmp/crowdin_backport/#{locale}.md")

    comparisons = DecidimApp::CrowdinBackport::Runner.new(
      locale:,
      target: DecidimApp::CrowdinBackport::LockedSource.new,
      source:,
      corrections: ENV["CORRECTIONS"] == "true"
    ).call(output:, report:)

    totals = [:applied, :renamed, :corrections, :skipped].index_with { |bucket| comparisons.sum { |c| c.public_send(bucket).size } }
    puts "Wrote #{output.relative_path_from(Rails.root)} and #{report.relative_path_from(Rails.root)}"
    puts totals.map { |bucket, count| "#{bucket}: #{count}" }.join(", ")
  end
end
