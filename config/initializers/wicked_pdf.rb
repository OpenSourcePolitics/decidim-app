# frozen_string_literal: true

require "base64"
require "mime/types"

Rails.application.config.after_initialize do
  if defined?(WickedPdf::WickedPdfHelper::Assets)
    WickedPdf::WickedPdfHelper::Assets.module_eval do
      def wicked_pdf_asset_base64(path)
        asset_path = Rails.public_path.join("packs", path)
        if asset_path.exist?
          base64 = Base64.strict_encode64(asset_path.read)
          mime_type = MIME::Types.type_for(path).first || "application/octet-stream"
          "data:#{mime_type};base64,#{Rack::Utils.escape(base64)}"
        else
          path
        end
      end

      def wicked_pdf_stylesheet_link_tag(*sources)
        sources.collect do |source|
          source = source.to_s
          source = "#{source}.css" unless source.end_with?(".css")
          asset_path = Rails.public_path.join("packs", source)
          if asset_path.exist?
            "<style>#{asset_path.read}</style>"
          else
            ""
          end
        end.join("\n").html_safe
      end

      def wicked_pdf_javascript_include_tag(*sources)
        sources.collect do |source|
          source = source.to_s
          source = "#{source}.js" unless source.end_with?(".js")
          asset_path = Rails.public_path.join("packs", source)
          if asset_path.exist?
            "<script>#{asset_path.read}</script>"
          else
            ""
          end
        end.join("\n").html_safe
      end
    end
  end
end
