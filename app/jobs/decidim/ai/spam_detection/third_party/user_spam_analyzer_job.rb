# frozen_string_literal: true

module Decidim
  module Ai
    module SpamDetection
      module ThirdParty
        class UserSpamAnalyzerJob < Decidim::Ai::SpamDetection::UserSpamAnalyzerJob
          def perform(reportable)
            @author = reportable
            @organization = reportable.organization
            klass = reportable.class.to_s
            contents = [
              "### nickname:",
              reportable.nickname.to_s,
              "### about:",
              translated_attribute(reportable.about).to_s,
              "### locale:",
              reportable.locale.to_s
            ]

            if reportable.personal_url.present?
              contents << "### personal_url:"
              contents << reportable.personal_url.to_s
            end

            classifier.classify(contents.join("\n"), @organization.host, klass)

            return unless classifier.score >= Decidim::Ai::SpamDetection.user_score_threshold

            if Decidim::UserModeration.find_by(user: reporting_user).present?
              Rails.logger.warn("[decidim-ai] User already moderated: ##{reportable.id} #{reportable.nickname}")
              return
            end

            Decidim::CreateUserReport.call(form, reportable)
          end
        end
      end
    end
  end
end
