# frozen_string_literal: true

require "fileutils"
require "open3"
require "yaml"

module DecidimApp
  # Backports translations made on Crowdin, which only land on Decidim's
  # `develop` branch, into the Decidim version locked in this app.
  #
  # Locale data is passed per module as flat hashes whose keys are arrays of
  # path segments (see `.flatten`), so the comparison itself needs no git, gems
  # or files.
  module CrowdinBackport
    PLURAL_KEYS = %w(zero one two few many other).freeze
    PLACEHOLDER = /%\{(\w+)\}/
    HTML_TAG = %r{</?([a-zA-Z][a-zA-Z0-9]*)}
    MIN_RENAME_WORDS = 3
    # Modules used only to develop or generate apps.
    IGNORED_MODULES = %w(decidim-dev decidim-generators).freeze

    Entry = Struct.new(:mod, :key, :value, :en, :source_en, :previous, :source_key, :reason, :candidates, keyword_init: true) do
      def dotted_key = key.join(".")

      def dotted_source_key = source_key&.join(".")
    end

    def self.flatten(hash, prefix = [], out = {})
      hash.each do |key, value|
        path = prefix + [key.to_s]
        if value.is_a?(Hash) && !plural?(value)
          flatten(value, path, out)
        else
          out[path] = value
        end
      end
      out
    end

    def self.plural?(value)
      value.is_a?(Hash) && value.any? && value.keys.all? { |key| PLURAL_KEYS.include?(key.to_s) }
    end

    def self.strings(value)
      case value
      when String then [value]
      when Hash then value.values.flat_map { |v| strings(v) }
      when Array then value.flat_map { |v| strings(v) }
      else []
      end
    end

    def self.blank_value?(value)
      strings(value).all? { |string| string.strip.empty? }
    end

    # A value counts as translated when it has text and is not a copy of the
    # English source.
    def self.translated?(value, english)
      !value.nil? && !blank_value?(value) && value != english
    end

    def self.placeholders(value)
      strings(value).flat_map { |string| string.scan(PLACEHOLDER).flatten }.to_set - ["count"]
    end

    def self.html_tags(value)
      strings(value).flat_map { |string| string.scan(HTML_TAG).flatten.map(&:downcase) }.tally
    end

    # Compares the locked (target) and develop (source) locale data of one
    # module and sorts every candidate key into a bucket.
    class Comparison
      attr_reader :mod, :applied, :renamed, :corrections, :skipped

      def initialize(mod:, target_en:, target_locale:, source_en:, source_locale:)
        @mod = mod
        @target_en = target_en
        @target_locale = target_locale
        @source_en = source_en
        @source_locale = source_locale
        @applied = []
        @renamed = []
        @corrections = []
        @skipped = []
      end

      def call
        @target_en.each do |key, english|
          next if CrowdinBackport.strings(english).empty?

          if @source_en.has_key?(key)
            compare_same_key(key, english)
          else
            compare_renamed_key(key, english)
          end
        end
        self
      end

      private

      def compare_same_key(key, english)
        source_value = @source_locale[key]
        return unless CrowdinBackport.translated?(source_value, @source_en[key])

        current = @target_locale[key]
        bucket = if !CrowdinBackport.translated?(current, english)
                   @applied
                 elsif current != source_value
                   @corrections
                 end
        return unless bucket

        entry = Entry.new(mod: @mod, key:, value: source_value, en: english, source_en: @source_en[key], previous: current, source_key: key)
        return skip(entry, :english_changed) if @source_en[key] != english

        check_and_add(bucket, entry)
      end

      # The key does not exist on develop any more (renamed or removed). Look
      # for develop keys of the same module with the exact same English text.
      def compare_renamed_key(key, english)
        current = @target_locale[key]
        return if CrowdinBackport.translated?(current, english)

        candidates = @source_en.select do |source_key, source_english|
          source_english == english && CrowdinBackport.translated?(@source_locale[source_key], source_english)
        end
        return if candidates.empty?

        values = candidates.keys.map { |source_key| @source_locale[source_key] }.uniq
        entry = Entry.new(mod: @mod, key:, value: values.first, en: english, source_en: english, previous: current, source_key: candidates.keys.first)
        if values.size > 1
          entry.candidates = candidates.keys.to_h { |source_key| [source_key.join("."), @source_locale[source_key]] }
          return skip(entry, :ambiguous_rename)
        end
        return skip(entry, :weak_rename) unless strong_rename?(key, candidates.keys, english)

        check_and_add(@renamed, entry)
      end

      # A short English text ("Date", "Cancel") matched under another key name
      # may come from another context, where the translation does not fit.
      def strong_rename?(key, source_keys, english)
        source_keys.any? { |source_key| source_key.last == key.last } ||
          CrowdinBackport.strings(english).sum { |string| string.split.size } >= MIN_RENAME_WORDS
      end

      def check_and_add(bucket, entry)
        if CrowdinBackport.placeholders(entry.value) != CrowdinBackport.placeholders(entry.en)
          skip(entry, :placeholders)
        elsif CrowdinBackport.html_tags(entry.value) != CrowdinBackport.html_tags(entry.en)
          skip(entry, :html)
        else
          bucket << entry
        end
      end

      def skip(entry, reason)
        entry.reason = reason
        @skipped << entry
      end
    end

    # Locale files of the Decidim version locked in Gemfile.lock, read from the
    # installed gems.
    class LockedSource
      def initialize(specs: Bundler.load.specs)
        core = specs.find { |spec| spec.name == "decidim-core" } || raise("decidim-core is not in the bundle")
        @root = File.dirname(core.full_gem_path)
        @revision = core.source.respond_to?(:revision) ? core.source.revision : core.version.to_s
        @modules = specs.select { |spec| spec.name.start_with?("decidim") && File.dirname(spec.full_gem_path) == @root }
                        .map { |spec| File.basename(spec.full_gem_path) }
                        .uniq.sort - IGNORED_MODULES
      end

      attr_reader :modules, :revision

      def read(mod, locale)
        path = File.join(@root, mod, "config", "locales", "#{locale}.yml")
        return {} unless File.exist?(path)

        CrowdinBackport.load_yaml(File.read(path), locale)
      end
    end

    # Locale files of a Decidim git ref. By default a shallow, sparse clone of
    # decidim/decidim `develop` kept in tmp/, refreshed on every run.
    class GitSource
      URL = "https://github.com/decidim/decidim.git"
      BRANCH = "develop"

      def initialize(path:, ref: nil)
        @path = path.to_s
        @managed = ref.nil?
        @ref = ref || "HEAD"
      end

      def prepare!
        return unless @managed

        if File.directory?(File.join(@path, ".git"))
          git("fetch", "--depth", "1", "origin", BRANCH)
          git("reset", "--hard", "FETCH_HEAD")
        else
          FileUtils.mkdir_p(File.dirname(@path))
          run("git", "clone", "--depth", "1", "--branch", BRANCH, "--filter=blob:none", "--sparse", URL, @path)
          git("sparse-checkout", "set", "--no-cone", "/*/config/locales/*.yml")
        end
      end

      def revision = git("rev-parse", @ref).strip

      def read(mod, locale)
        out, _err, status = Open3.capture3("git", "-C", @path, "show", "#{@ref}:#{mod}/config/locales/#{locale}.yml")
        return {} unless status.success?

        CrowdinBackport.load_yaml(out, locale)
      end

      private

      def git(*args) = run("git", "-C", @path, *args)

      def run(*command)
        out, err, status = Open3.capture3(*command)
        raise "#{command.join(" ")} failed: #{err}" unless status.success?

        out
      end
    end

    def self.load_yaml(content, locale)
      data = YAML.safe_load(content, permitted_classes: [Symbol], aliases: true) || {}
      flatten(data[locale.to_s] || {})
    end

    # Builds the nested locale hash for the given entries, keys sorted.
    def self.to_locale_hash(locale, entries)
      tree = {}
      entries.each do |entry|
        *parents, leaf = entry.key
        parents.inject(tree) { |node, segment| node[segment] ||= {} }[leaf] = entry.value
      end
      { locale.to_s => deep_sort(tree) }
    end

    def self.deep_sort(value)
      return value unless value.is_a?(Hash)

      value.sort_by { |key, _| key.to_s }.to_h.transform_values { |v| deep_sort(v) }
    end

    # Runs the comparison for every module and writes the locale file and the
    # report. Returns the comparisons.
    class Runner
      def initialize(locale:, target:, source:, corrections: false)
        @locale = locale.to_s
        @target = target
        @source = source
        @corrections = corrections
      end

      def call(output:, report:)
        @source.prepare!
        comparisons = @target.modules.map do |mod|
          Comparison.new(
            mod:,
            target_en: @target.read(mod, "en"),
            target_locale: @target.read(mod, @locale),
            source_en: @source.read(mod, "en"),
            source_locale: @source.read(mod, @locale)
          ).call
        end
        write_locale_file(output, comparisons)
        write_report(report, comparisons)
        comparisons
      end

      private

      def entries_to_write(comparisons)
        comparisons.flat_map do |comparison|
          comparison.applied + comparison.renamed + (@corrections ? comparison.corrections : [])
        end
      end

      def write_locale_file(output, comparisons)
        entries = entries_to_write(comparisons)
        header = "# Generated by `bin/rails \"decidim_app:crowdin_backport[#{@locale}]\"`: do not edit by hand.\n" \
                 "# Decidim #{@target.revision} <- develop #{@source.revision}\n"
        File.write(output, header + CrowdinBackport.to_locale_hash(@locale, entries).to_yaml(line_width: -1))
      end

      def write_report(report, comparisons)
        FileUtils.mkdir_p(File.dirname(report))
        File.write(report, Report.new(@locale, comparisons, @target.revision, @source.revision, @corrections).to_markdown)

        review = Review.new(@locale, comparisons, corrections_applied: @corrections)
        base = File.join(File.dirname(report), "#{@locale}_review")
        File.write("#{base}.csv", review.to_csv)
        review.to_workbook.write("#{base}.xlsx")
        File.binwrite("#{base}.ods", review.to_ods)
      end
    end

    class Report
      def initialize(locale, comparisons, target_revision, source_revision, corrections)
        @locale = locale
        @comparisons = comparisons
        @target_revision = target_revision
        @source_revision = source_revision
        @corrections = corrections
      end

      def to_markdown
        [
          "# Crowdin backport: #{@locale}",
          "",
          "Locked Decidim `#{@target_revision}`, develop `#{@source_revision}`.",
          "",
          summary,
          section("Renamed keys (applied, English text matched on another develop key)", :renamed, source: true),
          section("Corrections (#{@corrections ? "applied" : "NOT applied, rerun with CORRECTIONS=true"})", :corrections, previous: true),
          section("Skipped", :skipped, reason: true),
          section("Applied", :applied)
        ].join("\n")
      end

      def summary
        rows = @comparisons.map do |c|
          "| #{c.mod} | #{c.applied.size} | #{c.renamed.size} | #{c.corrections.size} | #{c.skipped.size} |"
        end
        totals = [:applied, :renamed, :corrections, :skipped].map { |bucket| @comparisons.sum { |c| c.public_send(bucket).size } }
        ["| Module | Applied | Renamed | Corrections | Skipped |", "|---|---|---|---|---|", *rows, "| **Total** | #{totals.join(" | ")} |", ""].join("\n")
      end

      def section(title, bucket, source: false, previous: false, reason: false)
        entries = @comparisons.flat_map { |c| c.public_send(bucket) }
        lines = ["## #{title} (#{entries.size})", ""]
        entries.each do |entry|
          lines << "- `#{entry.dotted_key}` (#{entry.mod})"
          lines << "  - develop key: `#{entry.dotted_source_key}`" if source
          lines << "  - reason: #{entry.reason}" if reason
          entry.candidates&.each { |key, value| lines << "  - candidate `#{key}`: #{value.inspect}" }
          lines << "  - en: #{entry.en.inspect}"
          lines << "  - en on develop: #{entry.source_en.inspect}" if entry.source_en != entry.en
          lines << "  - current: #{entry.previous.inspect}" if previous
          lines << "  - #{@locale}: #{entry.value.inspect}"
        end
        (lines << "").join("\n")
      end
    end
  end
end

require_relative "crowdin_backport/review"
