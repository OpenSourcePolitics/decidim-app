# frozen_string_literal: true

module Decidim
  module Ai
    module SpamDetection
      # Événement unique utilisé pour le résumé IA
      class SpamDigestEvent < Decidim::Events::BaseEvent
        def email_intro
          I18n.t(
            "decidim.ai.spam_detection.digest.summary",
            count: spam_count,
            frequency_label:
          )
        end

        def notification_title
          I18n.t(
            "decidim.ai.spam_detection.digest.summary",
            count: spam_count,
            frequency_label:
          )
        end

        def resource_title
          I18n.t("decidim.ai.spam_detection.digest.title")
        end

        def resource_path
          Decidim::Core::Engine.routes.url_helpers.admin_reports_path
        end

        def show_extended_information?
          false
        end

        private

        def spam_count
          extra[:spam_count] || 0
        end

        def frequency_label
          I18n.t("decidim.ai.spam_detection.digest.frequency_label.#{extra[:frequency] || 'daily'}")
        end
      end
    end
  end
end
