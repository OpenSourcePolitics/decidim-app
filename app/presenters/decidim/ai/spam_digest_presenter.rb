# frozen_string_literal: true

module Decidim
  module Ai
    # Présente le contenu du mail digest pour les spams IA
    class SpamDigestPresenter < SimpleDelegator
      def subject
        I18n.t("decidim.ai.spam_digest_mailer.subject")
      end

      def header
        I18n.t("decidim.ai.spam_digest_mailer.header")
      end

      def greeting
        I18n.t("decidim.ai.spam_digest_mailer.greeting", name:)
      end

      def intro
        I18n.t("decidim.ai.spam_digest_mailer.intro")
      end

      def outro
        I18n.t("decidim.ai.spam_digest_mailer.outro")
      end

      def see_more
        I18n.t("decidim.ai.spam_digest_mailer.see_more")
      end
    end
  end
end

