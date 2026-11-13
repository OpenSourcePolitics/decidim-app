# frozen_string_literal: true

module DecidimApp
  module CrowdinBackport
    # Review sheet for the client's translators: the translations someone must
    # judge (renamed keys, corrections, skipped keys). Translations applied
    # under the same key, with the same English text, come straight from
    # Crowdin and are left out. Plural forms and list items get one row each.
    class Review
      DECISIONS = %w(OK Change Reject).freeze
      REVIEWER_COLUMNS = [3, 4, 5].freeze
      WIDTHS = [50, 50, 50, 14, 50, 30, 12, 60, 40, 50, 50].freeze
      HEADER_FILL = "D9D9D9"
      REVIEWER_FILL = "FFF2CC"
      DECISION_FILLS = { "OK" => "C6EFCE", "Change" => "FFD8A8", "Reject" => "FFC7CE" }.freeze

      # [order, explanation]: rows are grouped in this order.
      WHY = {
        renamed: [1, "Crowdin translation of the same English text, found under another key. Check it fits here."],
        reworded: [2, "Crowdin translated the same English text, slightly reworded since (see \"Newer English\"). Same meaning."],
        completed: [3, "Crowdin fills items missing from the translation shown today."],
        corrections: [4, "Crowdin completes the translation shown today."],
        english_changed: [3, "Crowdin translated a newer English text (see \"Newer English\"). Adapt it to the English used here."],
        weak_rename: [4, "Short text that Crowdin translated for another screen. Check it fits here."],
        ambiguous_rename: [5, "Crowdin has several translations for this text. Pick one or write yours."],
        placeholders: [6, "The %{...} variables differ from the English. Fix them."],
        html: [7, "The HTML tags differ from the English. Fix them."]
      }.freeze

      def initialize(locale, comparisons, corrections_applied:, shortlist: false)
        @locale = locale
        @code = locale.to_s.upcase
        @comparisons = comparisons
        @corrections_applied = corrections_applied
        @shortlist = shortlist
      end

      def headers
        [
          "Key", "English", "#{@code} (proposed)", "Decision", "Your #{@code}", "Comment",
          "Status", "Why review", "#{@code} shown today", "Newer English (Crowdin)", "Crowdin key"
        ]
      end

      def rows
        @rows ||= entries.flat_map { |entry, reason, applied| entry_rows(entry, reason, applied) }
      end

      def to_csv
        require "csv"
        # The BOM makes Excel read the file as UTF-8.
        "﻿#{CSV.generate { |csv| ([headers] + rows).each { |row| csv << row } }}"
      end

      def to_workbook
        require "rubyXL"
        require "rubyXL/convenience_methods"
        workbook = RubyXL::Workbook.new
        review_sheet(workbook[0])
        decision_highlight(workbook, workbook[0])
        instructions_sheet(workbook.add_worksheet("How to review"))
        workbook
      end

      def sheet_name = "Review #{@code}"

      def to_ods
        require_relative "ods"
        Ods.new(self).to_s
      end

      def instructions
        [
          "How to review the #{@code} translations from Crowdin",
          "",
          "Translations made on Crowdin only reach the newest Decidim version, not the one your platform runs, so they are being copied to your platform.",
          "Most of them are copied as is. The #{rows.size} rows of the \"Review #{@code}\" sheet need a human check.",
          "",
          "Fill in the yellow columns only:",
          "- Decision: OK, Change or Reject, from the list. The row turns green, orange or red once decided.",
          "- Your #{@code}: your text, when the decision is Change.",
          "- Comment: anything we should know.",
          "",
          "What the decision does:",
          "- Status \"Applied\" (the translation is already in the update): OK keeps it, Change uses \"Your #{@code}\", Reject goes back to \"#{@code} shown today\".",
          "- Status \"Not applied\": OK applies \"#{@code} (proposed)\", Change uses \"Your #{@code}\", Reject keeps \"#{@code} shown today\".",
          "",
          "Rules for your text:",
          "- Keep the variables written %{...} exactly as they are, e.g. %{count} or %{name}.",
          "- Keep HTML tags such as <strong>...</strong>.",
          "- Plural forms have one row each: .one, .few, .many, .other.",
          "",
          "Texts you already changed in Term Customizer keep your version on the platform.",
          "\"Why review\" explains each row. The last columns give context: the text shown today, the newer English text Crowdin translated, and the Crowdin key."
        ] + shortlist_note
      end

      def shortlist_note
        return [] unless @shortlist

        [
          "",
          "This is the short list. #{left_out_count} rows with an obvious answer were left out and are applied as proposed: " \
          "texts that only moved to another key, English texts only reworded (e.g. \"an error\" / \"a problem\"), and lists where only missing items are filled. " \
          "The full review file lists them too."
        ]
      end

      private

      # [[entry, reason, applied], ...] sorted by group, then key. The
      # shortlist leaves out the obvious ones.
      def entries
        list = all_entries
        list = list.reject { |entry, reason, _applied| obvious?(entry, reason) } if @shortlist
        list.sort_by { |entry, reason, applied| [applied ? 0 : 1, WHY.dig(reason, 0) || 99, entry.dotted_key] }
      end

      def all_entries
        @comparisons.flat_map do |comparison|
          comparison.renamed.map { |entry| [entry, :renamed, true] } +
            comparison.reworded.map { |entry| [entry, :reworded, true] } +
            comparison.completed.map { |entry| [entry, :completed, true] } +
            comparison.corrections.map { |entry| [entry, :corrections, @corrections_applied] } +
            comparison.skipped.map { |entry| [entry, entry.reason, false] }
        end
      end

      # Applied rows whose answer is almost surely OK: the key only moved (same
      # last segment, same English), the English was only reworded, or blank
      # list items are filled.
      def obvious?(entry, reason)
        case reason
        when :reworded, :completed then true
        when :renamed then entry.key.last == entry.source_key.last
        else false
        end
      end

      def left_out_count
        all_entries.sum { |entry, reason, applied| obvious?(entry, reason) ? entry_rows(entry, reason, applied).size : 0 }
      end

      def entry_rows(entry, reason, applied)
        status = applied ? "Applied" : "Not applied"
        why = WHY.dig(reason, 1) || reason.to_s
        return [ambiguous_row(entry, status, why)] if entry.candidates

        forms(entry).filter_map do |form, suffix|
          current = pick(entry.previous, form)
          proposed = pick(entry.value, form)
          # Corrections of lists or plural forms: only the items that change.
          next if entry.previous && current == proposed

          newer_english = entry.source_en == entry.en ? "" : english(entry.source_en, form)
          crowdin_key = entry.source_key == entry.key ? "" : "#{entry.dotted_source_key}#{suffix}"
          ["#{entry.dotted_key}#{suffix}", english(entry.en, form), proposed, "", "", "",
           status, why, current, newer_english, crowdin_key]
        end
      end

      def ambiguous_row(entry, status, why)
        options = entry.candidates.values.uniq.each_with_index.map { |value, index| "Option #{index + 1}: #{value}" }
        [entry.dotted_key, entry.en.to_s, options.join("\n"), "", "", "",
         status, why, entry.previous.to_s, "", entry.candidates.keys.join("\n")]
      end

      # [[form, key suffix], ...]: plural forms and list items of the value,
      # or a single [nil, ""] for a plain string.
      def forms(entry)
        case entry.value
        when Hash then entry.value.keys.map { |form| [form, ".#{form}"] }
        when Array then entry.value.each_index.map { |index| [index, "[#{index}]"] }
        else [[nil, ""]]
        end
      end

      # English has no "few" or "many" plural form: show "other" for those.
      def english(value, form)
        text = pick(value, form)
        text.empty? && value.is_a?(Hash) && form.is_a?(String) ? pick(value, "other") : text
      end

      def pick(value, form)
        return value.to_s if form.nil?
        return "" unless value.is_a?(Hash) || value.is_a?(Array)

        (value.is_a?(Hash) ? value[form] || value[form.to_sym] : value[form]).to_s
      end

      def review_sheet(sheet)
        sheet.sheet_name = sheet_name
        ([headers] + rows).each_with_index do |row, r|
          row.each_with_index do |value, c|
            cell = sheet.add_cell(r, c, value.to_s)
            cell.change_text_wrap(true)
            cell.change_vertical_alignment("top")
            cell.change_fill(REVIEWER_FILL) if r.positive? && REVIEWER_COLUMNS.include?(c)
          end
        end
        sheet.change_row_bold(0, true)
        sheet.change_row_fill(0, HEADER_FILL)
        WIDTHS.each_with_index { |width, c| sheet.change_column_width(c, width) }
        sheet.auto_filter = RubyXL::AutoFilter.new(ref: RubyXL::Reference.new(0, rows.size, 0, headers.size - 1))
        freeze_header(sheet)
        decision_dropdown(sheet)
      end

      def freeze_header(sheet)
        sheet.sheet_views = RubyXL::WorksheetViews.new
        sheet.sheet_views << RubyXL::WorksheetView.new(
          workbook_view_id: 0,
          pane: RubyXL::Pane.new(y_split: 1, top_left_cell: RubyXL::Reference.new(1, 0), state: "frozen", active_pane: "bottomLeft")
        )
      end

      def decision_dropdown(sheet)
        return if rows.empty?

        sheet.data_validations = RubyXL::DataValidations.new
        sheet.data_validations << RubyXL::DataValidation.new(
          type: "list",
          allow_blank: true,
          show_error_message: true,
          sqref: RubyXL::Sqref.new("D2:D#{rows.size + 1}"),
          formula1: RubyXL::Formula.new(expression: "\"#{DECISIONS.join(",")}\"")
        )
      end

      # Colours the whole row once a decision is picked (Excel conditional
      # formatting, so it follows the reviewer's edits).
      def decision_highlight(workbook, sheet)
        return if rows.empty?

        stylesheet = workbook.stylesheet
        stylesheet.dxfs ||= RubyXL::DXFs.new
        sheet.conditional_formatting ||= []
        DECISION_FILLS.each_with_index do |(decision, color), index|
          stylesheet.dxfs << RubyXL::DXF.new(fill: solid_fill(color))
          rule = RubyXL::ConditionalFormattingRule.new(type: "expression", dxf_id: stylesheet.dxfs.size - 1, priority: index + 1, stop_if_true: true)
          rule.formulas << RubyXL::Formula.new(expression: "$D2=\"#{decision}\"")
          sheet.conditional_formatting << RubyXL::ConditionalFormatting.new(sqref: RubyXL::Sqref.new("A2:K#{rows.size + 1}"), cf_rule: [rule])
        end
      end

      def solid_fill(color)
        rgb = RubyXL::Color.new(rgb: "FF#{color}")
        RubyXL::Fill.new(pattern_fill: RubyXL::PatternFill.new(pattern_type: "solid", fg_color: rgb, bg_color: rgb))
      end

      def instructions_sheet(sheet)
        instructions.each_with_index { |line, r| sheet.add_cell(r, 0, line).change_text_wrap(true) }
        sheet.change_row_bold(0, true)
        sheet.change_column_width(0, 120)
      end
    end
  end
end
