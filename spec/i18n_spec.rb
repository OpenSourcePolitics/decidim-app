# frozen_string_literal: true

require "spec_helper"
require "i18n/tasks"

describe "I18n sanity" do
  let(:locales) do
    ENV["ENFORCED_LOCALES"].presence || Decidim.available_locales.map(&:to_s).join(",")
  end

  let(:i18n) { I18n::Tasks::BaseTask.new({ locales: locales.split(",") }, config_file: nil) }
  let(:missing_keys) { i18n.missing_keys }
  let(:unused_keys) { i18n.unused_keys }
  let(:non_normalized_paths) { i18n.non_normalized_paths }
  let(:inconsistent_interpolations) { i18n.inconsistent_interpolations }

  it "does not have missing keys" do
    expect(missing_keys).to be_empty,
                            "Missing #{missing_keys.leaves.count} i18n keys, run `i18n-tasks missing' to show them"
  end

  it "does not have unused keys" do
    expect(unused_keys).to be_empty,
                           "#{unused_keys.leaves.count} unused i18n keys, run `i18n-tasks unused' to show them"
  end

  unless ENV["SKIP_NORMALIZATION"]
    it "is normalized" do
      error_message = "The following files need to be normalized:\n" \
                      "#{non_normalized_paths.map { |path| "  #{path}" }.join("\n")}\n" \
                      "Please run `bundle exec i18n-tasks normalize --locales #{locales}` to fix them"

      expect(non_normalized_paths).to be_empty, error_message
    end
  end

  it "does not have inconsistent interpolations" do
    error_message = "#{inconsistent_interpolations.leaves.count} i18n keys have inconsistent interpolations.\n" \
                    "Run `i18n-tasks check-consistent-interpolations' to show them"
    expect(inconsistent_interpolations).to be_empty, error_message
  end
end
