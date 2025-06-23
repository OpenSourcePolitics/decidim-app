# frozen_string_literal: true

# This file is a Decidim initializer for the AI module.
# It configures the Third Party Scaleway AI service.
# It is a working example of how to set up the AI module in Decidim.
# Can be added to : development_app/config/initializers/decidim_ai_third_party.rb

if Decidim.module_installed?(:ai)
  if Rails.application.secrets.dig(:decidim, :ai, :endpoint).blank? || Rails.application.secrets.dig(:decidim, :ai, :secret).blank?
    Rails.logger.warn "[decidim-ai] Initializer - AI endpoint or secret not configured. AI features will be disabled."

    # FIX: While building Docker image, endpoint and secret are not defined and crashes because default Bayes strategy try to reach Redis
    analyzers = [
      {
        name: :bayes,
        strategy: Decidim::Ai::SpamDetection::Strategy::Bayes,
        options: {
          adapter: "memory"
        }
      }
    ]
    Decidim::Ai::SpamDetection.resource_analyzers = analyzers
    Decidim::Ai::SpamDetection.user_analyzers = analyzers

    return
  end

  analyzers = [
    {
      name: :scaleway,
      strategy: Decidim::Ai::SpamDetection::Strategy::Scaleway,
      options: {
        endpoint: Rails.application.secrets.dig(:decidim, :ai, :endpoint),
        secret: Rails.application.secrets.dig(:decidim, :ai, :secret)
      }
    }
  ]

  Decidim::Ai::Language.formatter = "Decidim::Ai::Language::Formatter"

  Decidim::Ai::SpamDetection.reporting_user_email = Rails.application.secrets.dig(:decidim, :ai, :reporting_user_email)
  Decidim::Ai::SpamDetection.resource_analyzers = analyzers
  Decidim::Ai::SpamDetection.user_analyzers = analyzers

  Decidim::Ai::SpamDetection.resource_score_threshold = Rails.application.secrets.dig(:decidim, :ai, :resource_score_threshold)
  Decidim::Ai::SpamDetection.user_score_threshold = Rails.application.secrets.dig(:decidim, :ai, :user_score_threshold)
  Decidim::Ai::SpamDetection.resource_models = begin
    models = {}
    models["Decidim::Comments::Comment"] = "Decidim::Ai::SpamDetection::Resource::Comment" if Decidim.module_installed?("comments")
    models["Decidim::Debates::Debate"] = "Decidim::Ai::SpamDetection::Resource::Debate" if Decidim.module_installed?("debates")
    models["Decidim::Initiative"] = "Decidim::Ai::SpamDetection::Resource::Initiative" if Decidim.module_installed?("initiatives")
    models["Decidim::Meetings::Meeting"] = "Decidim::Ai::SpamDetection::Resource::Meeting" if Decidim.module_installed?("meetings")
    models["Decidim::Proposals::Proposal"] = "Decidim::Ai::SpamDetection::Resource::Proposal" if Decidim.module_installed?("proposals")
    if Decidim.module_installed?("proposals")
      models["Decidim::Proposals::CollaborativeDraft"] =
        "Decidim::Ai::SpamDetection::Resource::CollaborativeDraft"
    end
    models
  end

  Decidim::Ai::SpamDetection.user_models = {
    "Decidim::User" => "Decidim::Ai::SpamDetection::Resource::UserBaseEntity"
  }

  Decidim::Ai::SpamDetection.user_detection_service = "Decidim::Ai::SpamDetection::ThirdPartyService"
  Decidim::Ai::SpamDetection.resource_detection_service = "Decidim::Ai::SpamDetection::ThirdPartyService"

  Decidim::Ai::SpamDetection.user_spam_analyzer_job = "Decidim::Ai::SpamDetection::ThirdParty::UserSpamAnalyzerJob"
  Decidim::Ai::SpamDetection.generic_spam_analyzer_job = "Decidim::Ai::SpamDetection::ThirdParty::GenericSpamAnalyzerJob"
end
