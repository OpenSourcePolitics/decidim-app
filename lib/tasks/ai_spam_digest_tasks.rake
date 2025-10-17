# frozen_string_literal: true

namespace :decidim do
  namespace :mailers do
    desc "Ajoute le résumé IA au digest quotidien"
    task spam_digest_daily: :environment do
      puts "[Decidim-AI] Génération du résumé IA quotidien..."
      Decidim::Ai::SpamDetection::SpamDigestGeneratorJob.perform_now(:daily)
    end

    desc "Ajoute le résumé IA au digest hebdomadaire"
    task spam_digest_weekly: :environment do
      puts "[Decidim-AI] Génération du résumé IA hebdomadaire..."
      Decidim::Ai::SpamDetection::SpamDigestGeneratorJob.perform_now(:weekly)
    end
  end
end
