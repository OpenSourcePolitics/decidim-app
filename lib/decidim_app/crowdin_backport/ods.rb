# frozen_string_literal: true

require "cgi"
require "zip"

module DecidimApp
  module CrowdinBackport
    # OpenDocument spreadsheet (.ods) version of the review sheet, for
    # LibreOffice users: same columns, Decision dropdown, row colour once a
    # decision is picked, filters, frozen header and instructions sheet.
    class Ods
      MIMETYPE = "application/vnd.oasis.opendocument.spreadsheet"
      NAMESPACES = {
        "office" => "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
        "style" => "urn:oasis:names:tc:opendocument:xmlns:style:1.0",
        "text" => "urn:oasis:names:tc:opendocument:xmlns:text:1.0",
        "table" => "urn:oasis:names:tc:opendocument:xmlns:table:1.0",
        "fo" => "urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0",
        "of" => "urn:oasis:names:tc:opendocument:xmlns:of:1.2",
        "config" => "urn:oasis:names:tc:opendocument:xmlns:config:1.0"
      }.freeze
      # Excel column widths are in characters.
      CM_PER_CHAR = 0.19

      def initialize(review)
        @review = review
      end

      def to_s
        buffer = Zip::OutputStream.write_buffer do |zip|
          # The mimetype must come first, uncompressed.
          zip.put_next_entry("mimetype", nil, nil, Zip::Entry::STORED)
          zip.write(MIMETYPE)
          { "content.xml" => content, "styles.xml" => styles, "settings.xml" => settings, "META-INF/manifest.xml" => manifest }.each do |path, xml|
            zip.put_next_entry(path)
            zip.write(xml)
          end
        end
        buffer.string
      end

      private

      def rows = @review.rows

      def sheet = @review.sheet_name

      def last_row = rows.size + 1

      def xmlns(*prefixes) = prefixes.map { |prefix| %(xmlns:#{prefix}="#{NAMESPACES.fetch(prefix)}") }.join(" ")

      def esc(value) = CGI.escapeHTML(value.to_s)

      def color(hex) = "##{hex.downcase}"

      def content
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <office:document-content #{xmlns("office", "style", "text", "table", "fo", "of")} office:version="1.3">
          <office:automatic-styles>
          #{column_styles}
          #{cell_style("header", Review::HEADER_FILL, bold: true)}
          #{cell_style("body", nil, decision_maps: true)}
          #{cell_style("input", Review::REVIEWER_FILL, decision_maps: true)}
          #{cell_style("note", nil)}
          #{cell_style("title", nil, bold: true)}
          </office:automatic-styles>
          <office:body><office:spreadsheet>
          #{validations}
          #{review_table}
          #{instructions_table}
          <table:database-ranges>
          <table:database-range table:name="__Anonymous_Sheet_DB__0" table:target-range-address="#{range("A1", "K#{last_row}")}" table:display-filter-buttons="true"/>
          </table:database-ranges>
          </office:spreadsheet></office:body>
          </office:document-content>
        XML
      end

      def range(from, to) = "'#{esc(sheet)}'.#{from}:'#{esc(sheet)}'.#{to}"

      def column_styles
        widths = Review::WIDTHS + [120]
        widths.each_with_index.map do |width, index|
          %(<style:style style:name="co#{index}" style:family="table-column">) +
            %(<style:table-column-properties style:column-width="#{(width * CM_PER_CHAR).round(2)}cm"/></style:style>)
        end.join("\n")
      end

      def cell_style(name, fill, bold: false, decision_maps: false)
        background = fill ? %( fo:background-color="#{color(fill)}") : ""
        text = bold ? %(<style:text-properties fo:font-weight="bold"/>) : ""
        maps = decision_maps ? decision_map_entries : ""
        <<~XML.strip
          <style:style style:name="#{name}" style:family="table-cell"><style:table-cell-properties fo:wrap-option="wrap" style:vertical-align="top"#{background}/>#{text}#{maps}</style:style>
        XML
      end

      # Conditional styles: the whole row takes the decision's colour.
      def decision_map_entries
        Review::DECISION_FILLS.keys.map do |decision|
          %(<style:map style:condition="is-true-formula([.$D2]=&quot;#{decision}&quot;)" ) +
            %(style:apply-style-name="Decision_#{decision}" style:base-cell-address="'#{esc(sheet)}'.A2"/>)
        end.join
      end

      def validations
        list = Review::DECISIONS.map { |decision| "&quot;#{decision}&quot;" }.join(";")
        <<~XML.strip
          <table:content-validations><table:content-validation table:name="decision" table:condition="of:cell-content-is-in-list(#{list})" table:allow-empty-cell="true" table:display-list="unsorted" table:base-cell-address="'#{esc(sheet)}'.D2"><table:error-message table:display="true" table:message-type="stop"/></table:content-validation></table:content-validations>
        XML
      end

      def review_table
        columns = Review::WIDTHS.each_index.map { |index| %(<table:table-column table:style-name="co#{index}"/>) }.join
        header = row(@review.headers.map { |value| cell(value, "header") })
        body = rows.map do |values|
          row(values.each_with_index.map do |value, index|
            input = Review::REVIEWER_COLUMNS.include?(index)
            cell(value, input ? "input" : "body", validation: index == 3)
          end)
        end
        %(<table:table table:name="#{esc(sheet)}">#{columns}#{header}#{body.join}</table:table>)
      end

      def instructions_table
        lines = @review.instructions.each_with_index.map { |line, index| row([cell(line, index.zero? ? "title" : "note")]) }
        %(<table:table table:name="How to review"><table:table-column table:style-name="co#{Review::WIDTHS.size}"/>#{lines.join}</table:table>)
      end

      def row(cells) = "<table:table-row>#{cells.join}</table:table-row>"

      def cell(value, style, validation: false)
        validation_attribute = validation ? %( table:content-validation-name="decision") : ""
        paragraphs = value.to_s.split("\n", -1).map { |line| "<text:p>#{esc(line)}</text:p>" }.join
        if paragraphs.empty?
          %(<table:table-cell table:style-name="#{style}"#{validation_attribute}/>)
        else
          %(<table:table-cell table:style-name="#{style}" office:value-type="string"#{validation_attribute}>#{paragraphs}</table:table-cell>)
        end
      end

      def styles
        decision_styles = Review::DECISION_FILLS.map do |decision, fill|
          %(<style:style style:name="Decision_#{decision}" style:family="table-cell">) +
            %(<style:table-cell-properties fo:background-color="#{color(fill)}" fo:wrap-option="wrap" style:vertical-align="top"/></style:style>)
        end
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <office:document-styles #{xmlns("office", "style", "fo")} office:version="1.3">
          <office:styles>#{decision_styles.join}</office:styles>
          </office:document-styles>
        XML
      end

      # Freezes the header row of the review sheet.
      def settings
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <office:document-settings #{xmlns("office", "config")} office:version="1.3"><office:settings>
          <config:config-item-set config:name="ooo:view-settings"><config:config-item-map-indexed config:name="Views"><config:config-item-map-entry>
          <config:config-item config:name="ViewId" config:type="string">view1</config:config-item>
          <config:config-item-map-named config:name="Tables"><config:config-item-map-entry config:name="#{esc(sheet)}">
          <config:config-item config:name="VerticalSplitMode" config:type="short">2</config:config-item>
          <config:config-item config:name="VerticalSplitPosition" config:type="int">1</config:config-item>
          <config:config-item config:name="ActiveSplitRange" config:type="short">2</config:config-item>
          <config:config-item config:name="PositionBottom" config:type="int">1</config:config-item>
          </config:config-item-map-entry></config:config-item-map-named>
          <config:config-item config:name="ActiveTable" config:type="string">#{esc(sheet)}</config:config-item>
          </config:config-item-map-entry></config:config-item-map-indexed></config:config-item-set>
          </office:settings></office:document-settings>
        XML
      end

      def manifest
        files = %w(content.xml styles.xml settings.xml).map do |path|
          %(<manifest:file-entry manifest:full-path="#{path}" manifest:media-type="text/xml"/>)
        end
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.3">
          <manifest:file-entry manifest:full-path="/" manifest:version="1.3" manifest:media-type="#{MIMETYPE}"/>
          #{files.join("\n")}
          </manifest:manifest>
        XML
      end
    end
  end
end
