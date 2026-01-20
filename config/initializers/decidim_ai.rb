# frozen_string_literal: true

# This file is a Decidim initializer for the AI module.
# It configures the Third Party AI provider.
ai_enabled = Decidim::Env.new("DECIDIM_AI_ENABLED", true).to_boolean_string == "true"

if Decidim.module_installed?(:ai) && ai_enabled
  ai_endpoint = ENV.fetch("DECIDIM_AI_ENDPOINT", nil)
  ai_basic_auth = ENV.fetch("DECIDIM_AI_BASIC_AUTH", nil)

  if ai_endpoint.blank? || ai_basic_auth.blank?
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
      name: :ai_request_handler,
      strategy: Decidim::Ai::SpamDetection::AiRequestHandler::Strategy,
      options: {
        endpoint: ai_endpoint,
        basic_auth: ai_basic_auth
      }
    }
  ]

  Decidim::Ai::Language.formatter = "Decidim::Ai::Language::Formatter"

  Decidim::Ai::SpamDetection.reporting_user_email = ENV.fetch("DECIDIM_AI_REPORTING_USER_EMAIL", nil)
  Decidim::Ai::SpamDetection.resource_analyzers = analyzers
  Decidim::Ai::SpamDetection.user_analyzers = analyzers

  Decidim::Ai::SpamDetection.resource_score_threshold = Decidim::Env.new("DECIDIM_AI_RESOURCE_SCORE_THRESHOLD", 0.5).to_f
  Decidim::Ai::SpamDetection.user_score_threshold = Decidim::Env.new("DECIDIM_AI_USER_SCORE_THRESHOLD", 0.5).to_f
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
else
  Rails.logger.warn "[decidim-ai] Initializer - AI module is not installed or AI is disabled. AI features will be disabled."
  Rails.logger.warn "[decidim-ai] Initializer - AI enabled: #{Decidim::Env.new("DECIDIM_AI_ENABLED", true).to_boolean_string}"
end
