# frozen_string_literal: true

module Decidim
  module Ai
    module SpamDetection
      module ThirdParty
        class GenericSpamAnalyzerJob < Decidim::Ai::SpamDetection::GenericSpamAnalyzerJob
          def perform(reportable, author, locale, fields)
            return unless decidim_ai_enabled?

            @author = author
            @organization = reportable.organization
            klass = reportable.class.to_s
            overall_score = I18n.with_locale(locale) do
              contents = fields.map do |field|
                content = translated_attribute(reportable.send(field))
                if content.present?
                  "### #{field}:\n#{content}"
                else
                  ""
                end
              end

              classifier.classify(contents.join("\n"), @organization.host, klass)
              classifier.score
            end

            return unless overall_score >= Decidim::Ai::SpamDetection.resource_score_threshold

            Decidim::CreateReport.call(form, reportable)
          end

          private

          def decidim_ai_enabled?
            Rails.application.secrets.dig(:decidim, :ai, :enabled)
          end
        end
      end
    end
  end
end
