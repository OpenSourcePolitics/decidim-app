# frozen_string_literal: true

if Decidim.module_installed?(:ai)
  Decidim::Ai::Language.formatter = "Decidim::Ai::Language::Formatter"

  Decidim::Ai::SpamDetection.reporting_user_email = "your-admin@example.org"
  Decidim::Ai::SpamDetection.resource_score_threshold = 0.75 # default
  Decidim::Ai::SpamDetection.spam_detection_delay = 30.seconds # default
  Decidim::Ai::SpamDetection.resource_analyzers = [
    {
      name: :bayes,
      strategy: Decidim::Ai::SpamDetection::Strategy::Bayes,
      options: {
        adapter: ENV.fetch("DECIDIM_SPAM_DETECTION_BACKEND_RESOURCE", "redis"),
        params: { url: ENV.fetch("DECIDIM_SPAM_DETECTION_BACKEND_RESOURCE_REDIS_URL", "redis://localhost:6379/2") }
      }
    }
  ]
  Decidim::Ai::SpamDetection.resource_models = begin
                                                 models = {}
                                                 models["Decidim::Comments::Comment"] = "Decidim::Ai::SpamDetection::Resource::Comment" if Decidim.module_installed?("comments")
                                                 models["Decidim::Debates::Debate"] = "Decidim::Ai::SpamDetection::Resource::Debate" if Decidim.module_installed?("debates")
                                                 models["Decidim::Initiative"] = "Decidim::Ai::SpamDetection::Resource::Initiative" if Decidim.module_installed?("initiatives")
                                                 models["Decidim::Meetings::Meeting"] = "Decidim::Ai::SpamDetection::Resource::Meeting" if Decidim.module_installed?("meetings")
                                                 models["Decidim::Proposals::Proposal"] = "Decidim::Ai::SpamDetection::Resource::Proposal" if Decidim.module_installed?("proposals")
                                                 models["Decidim::Proposals::CollaborativeDraft"] = "Decidim::Ai::SpamDetection::Resource::CollaborativeDraft" if Decidim.module_installed?("proposals")
                                                 models
                                               end

  Decidim::Ai::SpamDetection.user_score_threshold = 0.75 # default
  Decidim::Ai::SpamDetection.user_analyzers = [
    {
      name: :bayes,
      strategy: Decidim::Ai::SpamDetection::Strategy::Bayes,
      options: {
        adapter: ENV.fetch("DECIDIM_SPAM_DETECTION_BACKEND_USER", "redis"),
        params: { url: ENV.fetch("DECIDIM_SPAM_DETECTION_BACKEND_USER_REDIS_URL", "redis://localhost:6379/3") }
      }
    }
  ]
  Decidim::Ai::SpamDetection.user_models = {
    "Decidim::User" => "Decidim::Ai::SpamDetection::Resource::UserBaseEntity"
  }
  Decidim::Ai::SpamDetection.user_detection_service = "Decidim::Ai::SpamDetection::Service"
  Decidim::Ai::SpamDetection.resource_detection_service = "Decidim::Ai::SpamDetection::Service"
end