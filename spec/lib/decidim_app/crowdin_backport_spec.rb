# frozen_string_literal: true

require "spec_helper"
require "decidim_app/crowdin_backport"

describe DecidimApp::CrowdinBackport do
  def flat(hash) = DecidimApp::CrowdinBackport.flatten(hash)

  describe ".flatten" do
    it "keeps plural forms as one value" do
      expect(flat("a" => { "b" => "x", "c" => { "one" => "1", "other" => "%{count}" } }))
        .to eq(%w(a b) => "x", %w(a c) => { "one" => "1", "other" => "%{count}" })
    end
  end

  describe DecidimApp::CrowdinBackport::Comparison do
    subject(:comparison) do
      described_class.new(
        mod: "decidim-core",
        target_en: flat(target_en),
        target_locale: flat(target_locale),
        source_en: flat(source_en),
        source_locale: flat(source_locale)
      ).call
    end

    let(:target_en) { { "a" => { "title" => "Title" } } }
    let(:source_en) { target_en }
    let(:target_locale) { {} }
    let(:source_locale) { { "a" => { "title" => "Názov" } } }

    def keys(bucket) = comparison.public_send(bucket).map(&:dotted_key)

    it "applies a translation missing from the locked version" do
      expect(keys(:applied)).to eq(["a.title"])
      expect(comparison.applied.first.value).to eq("Názov")
    end

    context "when the locked version copies the English text" do
      let(:target_locale) { { "a" => { "title" => "Title" } } }

      it "applies the develop translation" do
        expect(keys(:applied)).to eq(["a.title"])
      end
    end

    context "when the locked version has the same translation" do
      let(:target_locale) { source_locale }

      it "does nothing" do
        expect([:applied, :renamed, :corrections, :skipped].sum { |b| comparison.public_send(b).size }).to eq(0)
      end
    end

    context "when the locked version has another translation" do
      let(:target_locale) { { "a" => { "title" => "Titul" } } }

      it "lists it as a correction" do
        expect(keys(:corrections)).to eq(["a.title"])
        expect(comparison.corrections.first.previous).to eq("Titul")
      end
    end

    context "when the English text changed on develop" do
      let(:source_en) { { "a" => { "title" => "Page title" } } }

      it "skips it" do
        expect(keys(:applied)).to be_empty
        expect(comparison.skipped.first.reason).to eq(:english_changed)
      end
    end

    context "when develop is not translated either" do
      let(:source_locale) { { "a" => { "title" => "Title" } } }

      it "does nothing" do
        expect(keys(:applied) + keys(:skipped)).to be_empty
      end
    end

    context "when placeholders differ" do
      let(:target_en) { { "a" => { "title" => "Hello %{name}" } } }
      let(:source_locale) { { "a" => { "title" => "Ahoj" } } }

      it "skips it" do
        expect(comparison.skipped.first.reason).to eq(:placeholders)
      end
    end

    context "when HTML tags differ" do
      let(:target_en) { { "a" => { "title" => "<strong>Hi</strong>" } } }
      let(:source_locale) { { "a" => { "title" => "Ahoj" } } }

      it "skips it" do
        expect(comparison.skipped.first.reason).to eq(:html)
      end
    end

    context "with plural forms" do
      let(:target_en) { { "a" => { "count" => { "one" => "1 item", "other" => "%{count} items" } } } }
      let(:source_locale) { { "a" => { "count" => { "one" => "1 položka", "few" => "%{count} položky", "other" => "%{count} položiek" } } } }

      it "applies all the locale's forms" do
        expect(comparison.applied.first.value.keys).to eq(%w(one few other))
      end
    end

    context "when the key was renamed on develop" do
      let(:target_en) { { "answer_questionnaire" => { "new" => "New user?" } } }
      let(:source_en) { { "response_questionnaire" => { "new" => "New user?" } } }
      let(:source_locale) { { "response_questionnaire" => { "new" => "Nový účastník?" } } }

      it "applies it under the locked key" do
        expect(keys(:renamed)).to eq(["answer_questionnaire.new"])
        expect(comparison.renamed.first.dotted_source_key).to eq("response_questionnaire.new")
      end

      context "when a short English text matches under another key name" do
        let(:target_en) { { "timeline" => { "entry_date" => "Date" } } }
        let(:source_en) { { "milestone" => { "due_on" => "Date" } } }
        let(:source_locale) { { "milestone" => { "due_on" => "Dátum" } } }

        it "skips it" do
          expect(keys(:renamed)).to be_empty
          expect(comparison.skipped.first.reason).to eq(:weak_rename)
        end
      end

      context "when several develop keys match with different translations" do
        let(:source_en) { { "x" => { "new" => "New user?" }, "y" => { "new" => "New user?" } } }
        let(:source_locale) { { "x" => { "new" => "Nový účastník?" }, "y" => { "new" => "Nový používateľ?" } } }

        it "skips it" do
          expect(keys(:renamed)).to be_empty
          expect(comparison.skipped.first.reason).to eq(:ambiguous_rename)
        end
      end

      context "when several develop keys match with the same translation" do
        let(:source_en) { { "x" => { "new" => "New user?" }, "y" => { "new" => "New user?" } } }
        let(:source_locale) { { "x" => { "new" => "Nový účastník?" }, "y" => { "new" => "Nový účastník?" } } }

        it "applies it" do
          expect(keys(:renamed)).to eq(["answer_questionnaire.new"])
        end
      end
    end
  end

  describe DecidimApp::CrowdinBackport::Review do
    subject(:review) { described_class.new("sk", [comparison], corrections_applied: false) }

    let(:comparison) do
      DecidimApp::CrowdinBackport::Comparison.new(
        mod: "decidim-core",
        target_en: flat("a" => { "same" => "Same", "count" => { "one" => "1 vote", "other" => "%{count} votes" } }, "old" => { "new" => "New user?" }),
        target_locale: {},
        source_en: flat("a" => { "same" => "Same", "count" => { "one" => "One vote", "other" => "%{count} votes" } }, "renamed" => { "new" => "New user?" }),
        source_locale: flat("a" => { "same" => "Rovnaký", "count" => { "one" => "1 hlas", "few" => "%{count} hlasy" } }, "renamed" => { "new" => "Nový účastník?" })
      ).call
    end

    it "starts with the key, English and proposed translation, then the reviewer's columns" do
      expect(review.headers.first(6)).to eq(["Key", "English", "SK (proposed)", "Decision", "Your SK", "Comment"])
    end

    it "keeps renamed and skipped keys, applied first, one row per plural form, and leaves out plain applied keys" do
      expect(review.rows.map { |row| [row[0], row[6]] }).to eq(
        [
          ["old.new", "Applied"],
          ["a.count.one", "Not applied"],
          ["a.count.few", "Not applied"]
        ]
      )
      expect(review.rows.first[10]).to eq("renamed.new")
      expect(review.rows[1].values_at(1, 2, 8, 9)).to eq(["1 vote", "1 hlas", "", "One vote"])
    end

    it "writes a CSV readable by Excel" do
      expect(review.to_csv).to start_with("﻿Key,English,")
    end

    it "builds a workbook with the review and instructions sheets" do
      expect(review.to_workbook.worksheets.map(&:sheet_name)).to eq(["Review SK", "How to review"])
    end

    it "builds an OpenDocument spreadsheet with the mimetype first and both sheets" do
      entries = Zip::InputStream.open(StringIO.new(review.to_ods)) do |zip|
        names = []
        while (entry = zip.get_next_entry)
          names << [entry.name, zip.read.force_encoding(Encoding::UTF_8)]
        end
        names
      end

      expect(entries.first).to eq(["mimetype", "application/vnd.oasis.opendocument.spreadsheet"])
      content = entries.to_h.fetch("content.xml")
      expect(content).to include('table:name="Review SK"', 'table:name="How to review"', "<text:p>Nový účastník?</text:p>")
      expect(content).to include("of:cell-content-is-in-list(&quot;OK&quot;;&quot;Change&quot;;&quot;Reject&quot;)")
    end
  end

  describe ".to_locale_hash" do
    it "nests and sorts the keys under the locale" do
      entries = [
        DecidimApp::CrowdinBackport::Entry.new(key: %w(b x), value: "2"),
        DecidimApp::CrowdinBackport::Entry.new(key: %w(a y), value: "1")
      ]

      expect(described_class.to_locale_hash("sk", entries)).to eq("sk" => { "a" => { "y" => "1" }, "b" => { "x" => "2" } })
    end
  end
end
